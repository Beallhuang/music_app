//
//  MiniPlayerView.swift
//  MusicPlayer
//
//  迷你播放器组件
//

import SwiftUI

struct MiniPlayerView: View {
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        if player.currentSong != nil {
            HStack(spacing: 12) {
                // 专辑封面
                albumArt
                    .frame(width: 44, height: 44)

                // 歌曲信息
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.currentSong?.title ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(player.currentSong?.displayArtist ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // 播放控制
                HStack(spacing: 20) {
                    Button(action: {
                        player.togglePlayPause()
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        player.playNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "282840").opacity(0.95))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
            )
            .overlay(
                // 进度条
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(theme.accentColor.color.opacity(0.3), lineWidth: 1)

                    // 底部进度条
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.accentColor.color)
                        .frame(width: geometry.size.width * player.progress, height: 2)
                        .position(x: geometry.size.width * player.progress / 2, y: geometry.size.height - 1)
                }
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 5)
        }
    }

    private var albumArt: some View {
        Group {
            if let artwork = player.currentSong?.artwork, let uiImage = UIImage(data: artwork) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            MiniPlayerView()
        }
    }
}
