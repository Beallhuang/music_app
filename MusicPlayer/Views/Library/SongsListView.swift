//
//  SongsListView.swift
//  MusicPlayer
//
//  歌曲列表视图
//

import SwiftUI

struct SongsListView: View {
    let songs: [Song]
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(songs) { song in
                    SongRowView(song: song)
                        .onTapGesture {
                            player.play(song: song, in: songs)
                        }
                        .contextMenu {
                            // 收藏
                            Button(action: {
                                library.toggleFavorite(song)
                            }) {
                                Label(
                                    song.isFavorite ? "取消收藏" : "添加到收藏",
                                    systemImage: song.isFavorite ? "heart.slash" : "heart"
                                )
                            }

                            // 添加到歌单
                            Menu {
                                ForEach(library.playlists) { playlist in
                                    Button(playlist.name) {
                                        library.addSongToPlaylist(song, playlist: playlist)
                                    }
                                }
                            } label: {
                                Label("添加到歌单", systemImage: "text.badge.plus")
                            }

                            // 删除
                            Button(role: .destructive) {
                                library.removeSong(song)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Albums List View
struct AlbumsListView: View {
    let albums: [Album]
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15)
            ], spacing: 20) {
                ForEach(albums) { album in
                    AlbumCardView(album: album)
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 100)
        }
    }
}

struct AlbumCardView: View {
    let album: Album
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
            ZStack {
                if let artwork = album.artwork, let uiImage = UIImage(data: artwork) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let firstSongArt = album.songs.first?.artwork, let uiImage = UIImage(data: firstSongArt) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 专辑信息
            Text(album.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(album.artist ?? "")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
    }
}

// MARK: - Artists List View
struct ArtistsListView: View {
    let artists: [Artist]
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15)
            ], spacing: 20) {
                ForEach(artists) { artist in
                    ArtistCardView(artist: artist)
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 100)
        }
    }
}

struct ArtistCardView: View {
    let artist: Artist
    @StateObject private var theme = AppTheme.shared

    var body: some View {
        VStack(spacing: 8) {
            // 头像
            ZStack {
                if let artwork = artist.artwork, let uiImage = UIImage(data: artwork) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            // 艺术家名称
            Text(artist.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Text("\(artist.songCount) 首歌曲")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Playlists List View
struct PlaylistsListView: View {
    let playlists: [Playlist]
    var onCreatePlaylist: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // 创建歌单按钮
                Button(action: onCreatePlaylist) {
                    HStack(spacing: 12) {
                        ZStack {
                            Color.white.opacity(0.1)
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("创建新歌单")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 15)
                }

                // 歌单列表
                ForEach(playlists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        PlaylistRowView(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    SongsListView(songs: [])
}
