//
//  PlayerView.swift
//  MusicPlayer
//
//  播放主界面
//

import SwiftUI

struct PlayerView: View {
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var theme = AppTheme.shared

    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    @State private var showFullPlayer = false
    @State private var lyrics: Lyrics?
    @State private var lyricsScrollProxy: ScrollViewProxy?

    var body: some View {
        ZStack {
            // 背景模糊效果
            if theme.albumArtBlurBackground, let artwork = player.currentSong?.artwork, let uiImage = UIImage(data: artwork) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 50)
                    .overlay(Color.black.opacity(0.6))
                    .ignoresSafeArea()
            } else {
                Color.appBackground.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // 导航栏
                navigationBar

                // 歌曲信息
                songInfoView
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                // 歌词区域（固定高度，保留底部控件空间）
                if theme.showLyrics {
                    lyricsView
                        .padding(.top, 16)
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.38)
                } else {
                    Spacer()
                }

                // 进度条
                progressView
                    .padding(.top, 16)
                    .padding(.horizontal, 30)

                // 播放控制
                controlsView
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let song = player.currentSong {
                loadLyrics(for: song)
            }
        }
        .onChange(of: player.currentSong) { newSong in
            if let song = newSong {
                loadLyrics(for: song)
                library.addToRecentlyPlayed(song)
            }
        }
    }

    private func loadLyrics(for song: Song) {
        // 先尝试本地歌词
        if let local = LyricParserService.shared.loadLyrics(for: song) {
            lyrics = local
            return
        }
        // 再尝试远程歌词（通过 RemoteLibraryService 匹配）
        let remoteLibrary = RemoteLibraryService.shared
        if let remoteSong = remoteLibrary.songs.first(where: { $0.id == song.id }),
           remoteSong.lyricURL != nil {
            Task {
                if let content = await remoteLibrary.loadRemoteLyrics(for: remoteSong),
                   let parsed = LyricParserService.shared.loadRemoteLyrics(content: content) {
                    await MainActor.run { lyrics = parsed }
                }
            }
        }
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            Button(action: {
                // 下拉收起播放器
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Button(action: {
                // 更多选项
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }

    // MARK: - Song Info
    private var songInfoView: some View {
        VStack(spacing: 8) {
            Text(player.currentSong?.title ?? "未播放歌曲")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)

            if let artist = player.currentSong?.artist {
                Text("\(artist)\(player.currentSong?.album.map { " · \($0)" } ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 8) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    // 进度
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accentColor.color)
                        .frame(width: geometry.size.width * (isDragging ? dragProgress : player.progress), height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragProgress = max(0, min(1, value.location.x / geometry.size.width))
                        }
                        .onEnded { value in
                            let progress = value.location.x / geometry.size.width
                            let time = player.duration * progress
                            player.seek(to: time)
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)

            // 时间标签
            HStack {
                Text(isDragging ? formatTime(player.duration * dragProgress) : player.formattedCurrentTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text(player.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Controls
    private var controlsView: some View {
        HStack(spacing: 40) {
            // 随机播放
            Button(action: {
                player.toggleShuffle()
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(player.isShuffled ? theme.accentColor.color : .white.opacity(0.6))
            }

            // 上一曲
            Button(action: {
                player.playPrevious()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            // 播放/暂停
            Button(action: {
                player.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: theme.accentColor.color.opacity(0.4), radius: 10, x: 0, y: 5)

                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .offset(x: player.isPlaying ? 0 : 2)
                }
            }

            // 下一曲
            Button(action: {
                player.playNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            // 循环模式
            Button(action: {
                player.toggleRepeatMode()
            }) {
                Image(systemName: player.repeatMode.icon)
                    .font(.system(size: 20))
                    .foregroundColor(player.repeatMode.isActive ? theme.accentColor.color : .white.opacity(0.6))
            }
        }
    }

    // MARK: - Lyrics View
    private var lyricsView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(lyrics?.lines ?? []) { line in
                        lyricLineView(line)
                            .id(line.id)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }
            .onAppear {
                lyricsScrollProxy = proxy
            }
            .onChange(of: player.currentTime) { _ in
                scrollToCurrentLyric()
            }
        }
    }

    private func lyricLineView(_ line: LyricLine) -> some View {
        VStack(spacing: 4) {
            Text(line.text)
                .font(.system(size: isCurrentLyric(line) ? theme.lyricsFontSize.activeSize : theme.lyricsFontSize.size))
                .foregroundColor(isCurrentLyric(line) ? theme.accentColor.color : .white.opacity(0.4))
                .fontWeight(isCurrentLyric(line) ? .medium : .regular)

            if theme.showTranslation, let translation = line.translation {
                Text(translation)
                    .font(.system(size: theme.lyricsFontSize.size - 2))
                    .foregroundColor(isCurrentLyric(line) ? .white.opacity(0.8) : .white.opacity(0.3))
            }
        }
        .multilineTextAlignment(.center)
    }

    private func isCurrentLyric(_ line: LyricLine) -> Bool {
        guard let currentIndex = lyrics?.index(for: player.currentTime) else { return false }
        return lyrics?.lines[currentIndex].id == line.id
    }

    private func scrollToCurrentLyric() {
        guard let currentIndex = lyrics?.index(for: player.currentTime),
              let line = lyrics?.lines[currentIndex],
              let proxy = lyricsScrollProxy else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(line.id, anchor: .center)
        }
    }

    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PlayerView()
}
