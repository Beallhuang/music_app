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

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteControl()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Remote Control Setup
    private func setupRemoteControl() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 播放
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        // 暂停
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // 下一曲
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        // 上一曲
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        // 进度调整
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    // MARK: - Playback Control
    func play(song: Song, in playlist: [Song]? = nil) {
        if let playlist = playlist {
            self.playlist = playlist
            self.currentIndex = playlist.firstIndex(where: { $0.id == song.id })
        }

        currentSong = song

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

        var nextIndex: Int

        if isShuffled {
            nextIndex = Int.random(in: 0..<playlist.count)
        } else {
            nextIndex = (index + 1) % playlist.count
        }

        if repeatMode == .one {
            nextIndex = index
        }

        play(song: playlist[nextIndex], in: playlist)
    }

    func playPrevious() {
        guard let index = currentIndex else { return }

        // 如果播放超过3秒，重新播放当前歌曲
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        var previousIndex: Int

        if isShuffled {
            previousIndex = Int.random(in: 0..<playlist.count)
        } else {
            previousIndex = (index - 1 + playlist.count) % playlist.count
        }

        play(song: playlist[previousIndex], in: playlist)
    }

    func toggleShuffle() {
        isShuffled.toggle()
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
        // 移除旧的观察者
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        // 添加新的时间观察者
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.updateNowPlayingInfo()
        }

        // 监听播放完成
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                self?.handlePlaybackEnd()
            }
            .store(in: &cancellables)
    }

    private func handlePlaybackEnd() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            play()
        case .all, .off:
            if repeatMode == .all || currentIndex != playlist.count - 1 {
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
