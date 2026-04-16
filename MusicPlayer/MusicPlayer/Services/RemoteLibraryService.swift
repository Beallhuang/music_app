//
//  RemoteLibraryService.swift
//  MusicPlayer
//
//  远程 HTTP 文件服务器音乐库服务
//

import Foundation
import AVFoundation
import Combine

/// 远程歌曲条目（从服务器目录解析）
struct RemoteSong: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String?
    var album: String?
    var duration: TimeInterval
    var remoteURL: URL
    var lyricURL: URL?
    var artwork: Data?
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
        self.artwork = artwork
        self.isDownloaded = isDownloaded
        self.localURL = localURL
    }

    /// 播放时使用的 URL（优先本地缓存）
    var playbackURL: URL {
        localURL ?? remoteURL
    }

    /// 转换为 Song 模型（用于播放器）
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

    static func == (lhs: RemoteSong, rhs: RemoteSong) -> Bool {
        lhs.id == rhs.id
    }
}

/// 下载任务状态
enum DownloadState {
    case idle
    case downloading(progress: Double)
    case completed
    case failed(Error)
}

/// 远程音乐库服务
class RemoteLibraryService: NSObject, ObservableObject {
    static let shared = RemoteLibraryService()

    // MARK: - Published Properties
    @Published var songs: [RemoteSong] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var downloadStates: [UUID: DownloadState] = [:]

    // MARK: - Settings
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "remoteServerURL")
        }
    }

    // MARK: - Private
    private var urlSession: URLSession!
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    private let audioExtensions = ["mp3", "m4a", "flac", "wav", "aac", "ogg", "opus"]
    private let cacheDirectory: URL

    private override init() {
        serverURL = UserDefaults.standard.string(forKey: "remoteServerURL") ?? ""

        // 缓存目录
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = docs.appendingPathComponent("RemoteCache", isDirectory: true)

        super.init()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loadCachedSongs()
    }

    // MARK: - Server Scanning

    /// 扫描服务器目录，发现音频文件
    func scanServer() async {
        guard !serverURL.isEmpty, let baseURL = URL(string: serverURL) else {
            await setError("请先配置服务器地址")
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let discovered = try await scanDirectory(url: baseURL)
            let remoteSongs = await buildRemoteSongs(from: discovered, baseURL: baseURL)

            await MainActor.run {
                self.songs = remoteSongs
                self.isLoading = false
                self.saveCachedSongs()
            }
        } catch {
            await setError("扫描失败：\(error.localizedDescription)")
        }
    }

    /// 递归扫描目录，返回所有音频文件 URL
    private func scanDirectory(url: URL, depth: Int = 0) async throws -> [URL] {
        guard depth < 5 else { return [] } // 最多递归 5 层

        let html = try await fetchHTML(from: url)
        let links = parseLinks(from: html, baseURL: url)

        var audioFiles: [URL] = []

        await withTaskGroup(of: [URL].self) { group in
            for link in links {
                let ext = link.pathExtension.lowercased()
                if audioExtensions.contains(ext) {
                    audioFiles.append(link)
                } else if link.hasDirectoryPath || link.pathExtension.isEmpty {
                    // 可能是子目录
                    group.addTask {
                        (try? await self.scanDirectory(url: link, depth: depth + 1)) ?? []
                    }
                }
            }

            for await subFiles in group {
                audioFiles.append(contentsOf: subFiles)
            }
        }

        return audioFiles
    }

    /// 构建 RemoteSong 列表，并尝试匹配歌词文件
    private func buildRemoteSongs(from audioURLs: [URL], baseURL: URL) async -> [RemoteSong] {
        // 先获取同目录下所有 lrc 文件（用于匹配）
        var lrcMap: [String: URL] = [:]
        if let html = try? await fetchHTML(from: baseURL) {
            let links = parseLinks(from: html, baseURL: baseURL)
            for link in links where link.pathExtension.lowercased() == "lrc" {
                let name = link.deletingPathExtension().lastPathComponent.lowercased()
                lrcMap[name] = link
            }
        }

        return audioURLs.map { url in
            let fileName = url.deletingPathExtension().lastPathComponent
            let title = fileName
            let lyricURL = lrcMap[fileName.lowercased()]

            return RemoteSong(
                title: title,
                remoteURL: url,
                lyricURL: lyricURL
            )
        }
    }

    // MARK: - HTML Parsing

    private func fetchHTML(from url: URL) async throws -> String {
        let (data, response) = try await urlSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    /// 从 HTML 目录列表中解析链接
    private func parseLinks(from html: String, baseURL: URL) -> [URL] {
        var urls: [URL] = []

        // 匹配 <a href="..."> 标签
        let pattern = #"href="([^"#?]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        for match in matches {
            guard let hrefRange = Range(match.range(at: 1), in: html) else { continue }
            let href = String(html[hrefRange])

            // 跳过父目录和绝对路径（非本服务器）
            if href.hasPrefix("..") || href.hasPrefix("//") { continue }
            if href.hasPrefix("http") && !href.hasPrefix(baseURL.absoluteString) { continue }

            if let url = URL(string: href, relativeTo: baseURL)?.absoluteURL {
                // 避免重复和循环
                if url.absoluteString != baseURL.absoluteString {
                    urls.append(url)
                }
            }
        }

        return urls
    }

    // MARK: - Lyric Loading

    /// 异步加载远程歌词内容
    func loadRemoteLyrics(for song: RemoteSong) async -> String? {
        guard let lyricURL = song.lyricURL else { return nil }

        do {
            let (data, _) = try await urlSession.data(from: lyricURL)
            // 尝试 UTF-8，失败则尝试 GBK
            if let content = String(data: data, encoding: .utf8) {
                return content
            }
            let gbkEncoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(gbkEncoding)
            return String(data: data, encoding: String.Encoding(rawValue: nsEncoding))
        } catch {
            return nil
        }
    }

    // MARK: - Download / Cache

    /// 下载歌曲到本地缓存
    func downloadSong(_ song: RemoteSong) {
        guard downloadStates[song.id] == nil else { return }

        let task = urlSession.downloadTask(with: song.remoteURL)
        downloadTasks[song.id] = task
        downloadStates[song.id] = .downloading(progress: 0)
        task.resume()
    }

    /// 取消下载
    func cancelDownload(_ song: RemoteSong) {
        downloadTasks[song.id]?.cancel()
        downloadTasks.removeValue(forKey: song.id)
        downloadStates.removeValue(forKey: song.id)
    }

    /// 删除本地缓存
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
        // 验证本地文件是否还存在
        songs = cached.map { song in
            var s = song
            if let localURL = song.localURL, !FileManager.default.fileExists(atPath: localURL.path) {
                s.localURL = nil
                s.isDownloaded = false
            }
            return s
        }
    }

    // MARK: - Helpers

    private func setError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isLoading = false
        }
    }

    /// 缓存文件路径
    private func cacheURL(for song: RemoteSong) -> URL {
        let ext = song.remoteURL.pathExtension
        return cacheDirectory.appendingPathComponent("\(song.id.uuidString).\(ext)")
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
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0

        DispatchQueue.main.async {
            self.downloadStates[songID] = .downloading(progress: progress)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let downloadTask = task as? URLSessionDownloadTask,
              let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }

        DispatchQueue.main.async {
            self.downloadStates[songID] = .failed(error)
            self.downloadTasks.removeValue(forKey: songID)
        }
    }
}
