//
//  RemoteLibraryService.swift
//  MusicPlayer
//
//  远程 JSON 音乐库服务（支持封面图片 URL 和 ID3 内嵌封面）
//

import Foundation
import AVFoundation

// MARK: - JSON 数据结构

private struct RemoteSongEntry: Decodable {
    let title: String
    let artist: String?
    let album: String?
    let url: String
    let lyric: String?
    let artwork: String?  // 封面图片路径（相对或绝对 URL）
}

private struct RemoteLibraryJSON: Decodable {
    let songs: [RemoteSongEntry]
}

// MARK: - RemoteSong 模型

struct RemoteSong: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String?
    var album: String?
    var duration: TimeInterval
    var remoteURL: URL
    var lyricURL: URL?
    var artworkURL: URL?   // JSON 中指定的封面图片地址
    var artwork: Data?     // 已加载的封面数据
    var isDownloaded: Bool
    var localURL: URL?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String? = nil,
        album: String? = nil,
        duration: TimeInterval = 0,
        remoteURL: URL,
        lyricURL: URL? = nil,
        artworkURL: URL? = nil,
        artwork: Data? = nil,
        isDownloaded: Bool = false,
        localURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.remoteURL = remoteURL
        self.lyricURL = lyricURL
        self.artworkURL = artworkURL
        self.artwork = artwork
        self.isDownloaded = isDownloaded
        self.localURL = localURL
    }

    var playbackURL: URL { localURL ?? remoteURL }

    func toSong() -> Song {
        Song(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileURL: playbackURL,
            artwork: artwork,
            dateAdded: Date(),
            isFavorite: false
        )
    }

    static func == (lhs: RemoteSong, rhs: RemoteSong) -> Bool { lhs.id == rhs.id }
}

// MARK: - 下载状态

enum DownloadState {
    case idle
    case downloading(progress: Double)
    case completed
    case failed(Error)
}

// MARK: - RemoteLibraryService

class RemoteLibraryService: NSObject, ObservableObject {
    static let shared = RemoteLibraryService()

    @Published var songs: [RemoteSong] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var downloadStates: [UUID: DownloadState] = [:]

    /// JSON 文件完整 URL，例如 http://192.168.1.100:8080/music.json
    @Published var jsonURL: String {
        didSet { UserDefaults.standard.set(jsonURL, forKey: "remoteLibraryJSONURL") }
    }

    private var urlSession: URLSession!
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    private let cacheDirectory: URL

    private override init() {
        jsonURL = UserDefaults.standard.string(forKey: "remoteLibraryJSONURL") ?? ""
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = docs.appendingPathComponent("RemoteCache", isDirectory: true)
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loadCachedSongs()
    }

    // MARK: - Fetch JSON

    func fetchLibrary() async {
        guard !jsonURL.isEmpty, let url = URL(string: jsonURL) else {
            await setError("请先配置 JSON 文件地址")
            return
        }
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            // 禁用缓存，确保每次都从服务器拉取最新 JSON
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(RemoteLibraryJSON.self, from: data)
            let baseURL = url.deletingLastPathComponent()
            let newSongs = buildRemoteSongs(from: decoded.songs, baseURL: baseURL)

            await MainActor.run {
                // 保留已下载状态和已加载封面
                self.songs = newSongs.map { new in
                    if let existing = self.songs.first(where: { $0.remoteURL == new.remoteURL }) {
                        var merged = new
                        merged.isDownloaded = existing.isDownloaded
                        merged.localURL = existing.localURL
                        merged.artwork = existing.artwork
                        return merged
                    }
                    return new
                }
                self.isLoading = false
                self.saveCachedSongs()
            }
            // 后台异步加载封面，不阻塞列表显示
            Task { await self.loadArtworksIfNeeded() }

        } catch let e as DecodingError {
            await setError("JSON 格式错误：\(e.localizedDescription)")
        } catch {
            await setError("加载失败：\(error.localizedDescription)")
        }
    }

    // MARK: - Build Songs

    private func buildRemoteSongs(from entries: [RemoteSongEntry], baseURL: URL) -> [RemoteSong] {
        entries.compactMap { entry in
            guard let audioURL = resolveURL(entry.url, baseURL: baseURL) else { return nil }
            return RemoteSong(
                title: entry.title,
                artist: entry.artist,
                album: entry.album,
                remoteURL: audioURL,
                lyricURL: entry.lyric.flatMap { resolveURL($0, baseURL: baseURL) },
                artworkURL: entry.artwork.flatMap { resolveURL($0, baseURL: baseURL) }
            )
        }
    }

    private func resolveURL(_ string: String, baseURL: URL) -> URL? {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string)
        }
        return URL(string: string, relativeTo: baseURL)?.absoluteURL
    }

    // MARK: - Artwork Loading

    private func loadArtworksIfNeeded() async {
        let targets = await MainActor.run { songs.filter { $0.artwork == nil } }
        await withTaskGroup(of: (UUID, Data?).self) { group in
            for song in targets {
                group.addTask { [weak self] in
                    guard let self else { return (song.id, nil) }
                    return (song.id, await self.fetchArtwork(for: song))
                }
            }
            for await (id, data) in group {
                guard let data else { continue }
                await MainActor.run {
                    if let idx = self.songs.firstIndex(where: { $0.id == id }) {
                        self.songs[idx].artwork = data
                    }
                }
            }
        }
        await MainActor.run { saveCachedSongs() }
    }

    /// 优先用 JSON 指定的封面图片，其次从音频 ID3 标签提取
    private func fetchArtwork(for song: RemoteSong) async -> Data? {
        if let artworkURL = song.artworkURL,
           let (data, _) = try? await urlSession.data(from: artworkURL) {
            return data
        }
        return await extractEmbeddedArtwork(from: song.remoteURL)
    }

    /// 用 AVAsset 提取音频文件内嵌封面（mp3/m4a/flac 等）
    private func extractEmbeddedArtwork(from url: URL) async -> Data? {
        let asset = AVURLAsset(url: url)
        guard let items = try? await asset.load(.commonMetadata) else { return nil }
        for item in items where item.commonKey == .commonKeyArtwork {
            if let data = try? await item.load(.dataValue) { return data }
        }
        return nil
    }

    // MARK: - Lyric Loading

    func loadRemoteLyrics(for song: RemoteSong) async -> String? {
        guard let lyricURL = song.lyricURL else { return nil }
        do {
            let (data, _) = try await urlSession.data(from: lyricURL)
            if let content = String(data: data, encoding: .utf8) { return content }
            let enc = CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
            return String(data: data, encoding: String.Encoding(rawValue: enc))
        } catch { return nil }
    }

    // MARK: - Download / Cache

    func downloadSong(_ song: RemoteSong) {
        guard downloadStates[song.id] == nil else { return }
        let task = urlSession.downloadTask(with: song.remoteURL)
        downloadTasks[song.id] = task
        downloadStates[song.id] = .downloading(progress: 0)
        task.resume()
    }

    func cancelDownload(_ song: RemoteSong) {
        downloadTasks[song.id]?.cancel()
        downloadTasks.removeValue(forKey: song.id)
        downloadStates.removeValue(forKey: song.id)
    }

    func removeCache(for song: RemoteSong) {
        guard let idx = songs.firstIndex(where: { $0.id == song.id }),
              let localURL = songs[idx].localURL else { return }
        try? FileManager.default.removeItem(at: localURL)
        songs[idx].localURL = nil
        songs[idx].isDownloaded = false
        downloadStates.removeValue(forKey: song.id)
        saveCachedSongs()
    }

    // MARK: - Persistence

    private func saveCachedSongs() {
        if let data = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(data, forKey: "remoteSongsCache")
        }
    }

    private func loadCachedSongs() {
        guard let data = UserDefaults.standard.data(forKey: "remoteSongsCache"),
              let cached = try? JSONDecoder().decode([RemoteSong].self, from: data) else { return }
        songs = cached.map { song in
            var s = song
            if let localURL = song.localURL, !FileManager.default.fileExists(atPath: localURL.path) {
                s.localURL = nil; s.isDownloaded = false
            }
            return s
        }
    }

    private func setError(_ message: String) async {
        await MainActor.run { errorMessage = message; isLoading = false }
    }

    private func cacheURL(for song: RemoteSong) -> URL {
        cacheDirectory.appendingPathComponent("\(song.id.uuidString).\(song.remoteURL.pathExtension)")
    }
}

// MARK: - URLSessionDownloadDelegate

extension RemoteLibraryService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key,
              let idx = songs.firstIndex(where: { $0.id == songID }) else { return }
        let dest = cacheURL(for: songs[idx])
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            DispatchQueue.main.async {
                self.songs[idx].localURL = dest
                self.songs[idx].isDownloaded = true
                self.downloadStates[songID] = .completed
                self.downloadTasks.removeValue(forKey: songID)
                self.saveCachedSongs()
            }
        } catch {
            DispatchQueue.main.async {
                self.downloadStates[songID] = .failed(error)
                self.downloadTasks.removeValue(forKey: songID)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async { self.downloadStates[songID] = .downloading(progress: progress) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error,
              let downloadTask = task as? URLSessionDownloadTask,
              let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }
        DispatchQueue.main.async {
            self.downloadStates[songID] = .failed(error)
            self.downloadTasks.removeValue(forKey: songID)
        }
    }
}
