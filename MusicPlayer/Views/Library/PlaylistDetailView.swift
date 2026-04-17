//
//  PlaylistDetailView.swift
//  MusicPlayer
//
//  歌单详情页
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist

    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showRenameAlert = false
    @State private var newName = ""
    @State private var showDeleteConfirm = false

    // 从 library 中实时读取最新歌单数据
    private var currentPlaylist: Playlist? {
        library.playlists.first { $0.id == playlist.id }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let pl = currentPlaylist {
                VStack(spacing: 0) {
                    headerView(pl)
                    songListView(pl)
                }
            } else {
                // 歌单已被删除
                Text("歌单不存在")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .navigationBarHidden(true)
        .alert("重命名歌单", isPresented: $showRenameAlert) {
            TextField("歌单名称", text: $newName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                if !newName.isEmpty, let pl = currentPlaylist {
                    library.renamePlaylist(pl, newName: newName)
                }
            }
        }
        .confirmationDialog("删除歌单", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let pl = currentPlaylist {
                    library.deletePlaylist(pl)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复")
        }
    }

    // MARK: - Header
    private func headerView(_ pl: Playlist) -> some View {
        VStack(spacing: 16) {
            // 导航栏
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Menu {
                    Button {
                        newName = pl.name
                        showRenameAlert = true
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除歌单", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            // 封面
            ZStack {
                if let artwork = pl.artwork, let uiImage = UIImage(data: artwork) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let firstArt = pl.songs.first?.artwork, let uiImage = UIImage(data: firstArt) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [theme.accentColor.color, theme.accentColor.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: pl.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

            // 歌单信息
            VStack(spacing: 6) {
                Text(pl.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("\(pl.songCount) 首歌曲")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }

            // 播放按钮
            if !pl.songs.isEmpty {
                Button(action: {
                    player.play(song: pl.songs[0], in: pl.songs)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("播放全部")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 44)
                    .background(theme.accentColor.color)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Song List
    private func songListView(_ pl: Playlist) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if pl.songs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("还没有歌曲")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.4))
                        Text("长按歌曲选择「添加到歌单」")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(pl.songs) { song in
                        Button(action: { player.play(song: song, in: pl.songs) }) {
                            playlistSongRow(song, playlist: pl)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }

    private func playlistSongRow(_ song: Song, playlist pl: Playlist) -> some View {
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
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(player.currentSong?.id == song.id ? theme.accentColor.color : .white)
                    .lineLimit(1)

                Text(song.displayArtist)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Text(song.formattedDuration)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 15)
        .onTapGesture {
            player.play(song: song, in: pl.songs)
        }
        .contextMenu {
            Button(action: { library.toggleFavorite(song) }) {
                Label(song.isFavorite ? "取消收藏" : "添加到收藏",
                      systemImage: song.isFavorite ? "heart.slash" : "heart")
            }
            let otherPlaylists = library.playlists.filter { $0.id != pl.id }
            if !otherPlaylists.isEmpty {
                Menu {
                    ForEach(otherPlaylists) { other in
                        Button(other.name) {
                            library.addSongToPlaylist(song, playlist: other)
                        }
                    }
                } label: {
                    Label("添加到歌单", systemImage: "text.badge.plus")
                }
            }
            Button(role: .destructive) {
                library.removeSongFromPlaylist(song, playlist: pl)
            } label: {
                Label("从歌单移除", systemImage: "minus.circle")
            }
        }
    }
}
