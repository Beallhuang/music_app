//
//  MusicPlayerService.swift
//  MusicPlayer
//
//  音乐播放核心服务
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

/// 播放模式
enum RepeatMode: String, CaseIterable, Codable {
    case off = "关闭"
    case all = "列表循环"
    case one = "单曲循环"

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var isActive: Bool {
        self != .off
    }
}

/// 音乐播放器服务
class MusicPlayerService: NSObject, ObservableObject {
    static let shared = MusicPlayerService()

    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled = false
    @Published var playlist: [Song] = []
    @Published var currentIndex: Int?
    @Published var shuffleHistory: [Int] = [] // 随机播放历史记录

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var remoteCommandTargets: [Any] = []

    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteControl()
    }

    deinit {
        // 清理时间观察者
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        // 移除远程控制命令目标
        let commandCenter = MPRemoteCommandCenter.shared()
        for target in remoteCommandTargets {
            commandCenter.playCommand.removeTarget(target)
            commandCenter.pauseCommand.removeTarget(target)
            commandCenter.nextTrackCommand.removeTarget(target)
            commandCenter.previousTrackCommand.removeTarget(target)
            commandCenter.changePlaybackPositionCommand.removeTarget(target)
        }
        remoteCommandTargets.removeAll()

        // 清理订阅
        cancellables.removeAll()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Remote Control Setup
    private func setupRemoteControl() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 播放
        let playTarget = commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        remoteCommandTargets.append(playTarget)

        // 暂停
        let pauseTarget = commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        remoteCommandTargets.append(pauseTarget)

        // 下一曲
        let nextTarget = commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        remoteCommandTargets.append(nextTarget)

        // 上一曲
        let previousTarget = commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        remoteCommandTargets.append(previousTarget)

        // 进度调整
        let positionTarget = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime)
            return .success
        }
        remoteCommandTargets.append(positionTarget)
    }

    // MARK: - Playback Control
    func play(song: Song, in playlist: [Song]? = nil) {
        if let playlist = playlist {
            let isNewPlaylist = playlist.map({ $0.id }) != self.playlist.map({ $0.id })
            self.playlist = playlist
            self.currentIndex = playlist.firstIndex(where: { $0.id == song.id })
            if isNewPlaylist {
                shuffleHistory.removeAll()
            }
        } else {
            if let idx = self.playlist.firstIndex(where: { $0.id == song.id }) {
                self.currentIndex = idx
            }
        }

        currentSong = song

        // 检查文件是否存在（本地文件）
        if song.fileURL.isFileURL && !FileManager.default.fileExists(atPath: song.fileURL.path) {
            print("⚠️ 音频文件不存在: \(song.fileURL.path)")
        }

        // 先移除旧 player 的 time observer，再替换 player
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        let playerItem = AVPlayerItem(url: song.fileURL)
        player = AVPlayer(playerItem: playerItem)

        setupTimeObserver()
        setupNowPlayingInfo(song: song)

        player?.play()
        isPlaying = true
        duration = song.duration
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
    }

    func seekForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func seekBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    // MARK: - Playlist Control
    func playNext() {
        guard let index = currentIndex else { return }
        guard !playlist.isEmpty else { return }

        // 单曲循环模式下，重新播放当前歌曲
        if repeatMode == .one {
            seek(to: 0)
            play()
            return
        }

        var nextIndex: Int

        if isShuffled {
            // 记录当前索引到历史
            shuffleHistory.append(index)
            nextIndex = Int.random(in: 0..<playlist.count)
        } else {
            nextIndex = (index + 1) % playlist.count
        }

        // 边界检查
        guard nextIndex >= 0 && nextIndex < playlist.count else { return }
        play(song: playlist[nextIndex])
    }

    func playPrevious() {
        guard let index = currentIndex else { return }
        guard !playlist.isEmpty else { return }

        // 如果播放超过3秒，重新播放当前歌曲
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        var previousIndex: Int

        if isShuffled {
            // 从历史记录中获取上一个索引
            if let lastShuffleIndex = shuffleHistory.popLast() {
                previousIndex = lastShuffleIndex
            } else {
                // 没有历史记录时随机选择
                previousIndex = Int.random(in: 0..<playlist.count)
            }
        } else {
            previousIndex = (index - 1 + playlist.count) % playlist.count
        }

        // 边界检查
        guard previousIndex >= 0 && previousIndex < playlist.count else { return }
        play(song: playlist[previousIndex])
    }

    func toggleShuffle() {
        isShuffled.toggle()
        // 切换随机播放模式时清除历史记录
        shuffleHistory.removeAll()
    }

    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    // MARK: - Time Observer
    private func setupTimeObserver() {
        // 添加新的时间观察者
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.updateNowPlayingInfo()
        }

        // 清除旧的播放完成监听，再重新注册（避免重复触发）
        cancellables.removeAll()
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .filter { [weak self] notification in
                guard let currentItem = self?.player?.currentItem else { return false }
                return (notification.object as? AVPlayerItem) == currentItem
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackEnd()
            }
            .store(in: &cancellables)
    }

    private func handlePlaybackEnd() {
        switch repeatMode {
        case .one:
            let cmTime = CMTime(seconds: 0, preferredTimescale: 600)
            player?.seek(to: cmTime) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.player?.play()
                    self?.isPlaying = true
                    self?.currentTime = 0
                }
            }
        case .all:
            playNext()
        case .off:
            if currentIndex != playlist.count - 1 {
                playNext()
            } else {
                isPlaying = false
            }
        }
    }

    // MARK: - Now Playing Info
    private func setupNowPlayingInfo(song: Song) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.displayArtist,
            MPMediaItemPropertyAlbumTitle: song.displayAlbum,
            MPMediaItemPropertyPlaybackDuration: song.duration
        ]

        if let artwork = song.artwork, let image = UIImage(data: artwork) {
            let artworkItem = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artworkItem
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingInfo() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Utility
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}
