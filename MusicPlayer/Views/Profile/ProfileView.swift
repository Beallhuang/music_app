//
//  ProfileView.swift
//  MusicPlayer
//
//  个人中心页面
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // 用户头像区域
                        userProfileSection

                        // 听歌统计
                        statsSection

                        // 最近播放
                        if !library.recentlyPlayed.isEmpty {
                            recentPlaySection
                        }

                        // 我的收藏
                        if !library.favorites.isEmpty {
                            favoritesSection
                        }

                        // 播放历史统计
                        playHistorySection
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitle("个人中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("个人中心")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - User Profile Section
    private var userProfileSection: some View {
        VStack(spacing: 12) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 80, height: 80)
                .clipShape(Circle())

                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))
            }

            Text("音乐爱好者")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.top, 30)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 40) {
            StatItemView(value: "\(library.totalSongCount)", label: "总歌曲")
            StatItemView(value: "\(library.totalArtistCount)", label: "艺术家")
            StatItemView(value: "\(library.totalPlaylistCount)", label: "歌单")
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 15)
    }

    // MARK: - Recent Play Section
    private var recentPlaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("最近播放", systemImage: "clock")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Button("查看全部") {
                    // 导航到完整列表
                }
                .font(.system(size: 13))
                .foregroundColor(theme.accentColor.color)
            }
            .padding(.horizontal, 15)

            ForEach(library.recentlyPlayed.prefix(5)) { song in
                HStack(spacing: 12) {
                    // 封面
                    ZStack {
                        if let artwork = song.artwork, let uiImage = UIImage(data: artwork) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [theme.accentColor.color.opacity(0.8), theme.accentColor.color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(song.displayArtist)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("刚刚")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 15)
                .onTapGesture {
                    player.play(song: song, in: library.songs)
                }
            }
        }
    }

    // MARK: - Favorites Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("我的收藏", systemImage: "heart.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Button("查看全部") {
                    // 导航到完整列表
                }
                .font(.system(size: 13))
                .foregroundColor(theme.accentColor.color)
            }
            .padding(.horizontal, 15)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(library.favorites.prefix(10)) { song in
                        FavoriteSongCard(song: song)
                            .onTapGesture {
                                player.play(song: song, in: library.favorites)
                            }
                    }
                }
                .padding(.horizontal, 15)
            }
        }
    }

    // MARK: - Play History Section
    private var playHistorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("播放历史", systemImage: "calendar")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 15)

            HStack(spacing: 15) {
                HistoryItemView(title: "总歌曲", value: "\(library.totalSongCount)首")
                HistoryItemView(title: "收藏", value: "\(library.favorites.count)首")
                HistoryItemView(title: "最近播放", value: "\(library.recentlyPlayed.count)首")
            }
            .padding(.horizontal, 15)
        }
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let value: String
    let label: String
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.accentColor.color)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Favorite Song Card
struct FavoriteSongCard: View {
    let song: Song
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let artwork = song.artwork, let uiImage = UIImage(data: artwork) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(song.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            Text(song.displayArtist)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
        }
    }
}

// MARK: - History Item View
struct HistoryItemView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ProfileView()
}
