//
//  LibraryView.swift
//  MusicPlayer
//
//  音乐库管理主页面
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var theme = AppTheme.shared
    @StateObject private var importService = FileImportService.shared

    @State private var searchText = ""
    @State private var selectedTab: LibraryTab = .all
    @State private var showImportPicker = false
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""

    enum LibraryTab: String, CaseIterable {
        case all = "全部"
        case songs = "歌曲"
        case albums = "专辑"
        case artists = "艺术家"
        case playlists = "歌单"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 头部
                    headerView

                    // 搜索栏
                    searchBarView

                    // 分类标签
                    tabsView

                    // 内容区域
                    contentView
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePlaylist) {
                createPlaylistSheet
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("音乐库")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                importFiles()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(theme.accentColor.color)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 15)
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField("搜索歌曲、艺术家、专辑...", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 15)
    }

    // MARK: - Tabs
    private var tabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? theme.accentColor.color : Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .all:
            allContentView
        case .songs:
            SongsListView(songs: searchText.isEmpty ? library.songs : library.searchSongs(query: searchText))
        case .albums:
            AlbumsListView(albums: searchText.isEmpty ? library.albums : library.searchAlbums(query: searchText))
        case .artists:
            ArtistsListView(artists: searchText.isEmpty ? library.artists : library.searchArtists(query: searchText))
        case .playlists:
            PlaylistsListView(playlists: library.playlists, onCreatePlaylist: { showCreatePlaylist = true })
        }
    }

    // MARK: - All Content View
    private var allContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 最近添加
                if !library.recentlyAddedSongs.isEmpty {
                    SectionView(title: "最近添加") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(library.recentlyAddedSongs.prefix(10)) { song in
                                    SongCardView(song: song)
                                        .onTapGesture {
                                            playSong(song)
                                        }
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                    }
                }

                // 我的歌单
                if !library.playlists.isEmpty {
                    SectionView(title: "我的歌单", actionTitle: "创建", action: { showCreatePlaylist = true }) {
                        ForEach(library.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistRowView(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 所有歌曲
                if !library.songs.isEmpty {
                    SectionView(title: "全部歌曲") {
                        ForEach(library.songs) { song in
                            SongRowView(song: song)
                                .onTapGesture {
                                    playSong(song)
                                }
                                .contextMenu {
                                    Button(action: { library.toggleFavorite(song) }) {
                                        Label(song.isFavorite ? "取消收藏" : "添加到收藏",
                                              systemImage: song.isFavorite ? "heart.slash" : "heart")
                                    }
                                    Menu {
                                        ForEach(library.playlists) { playlist in
                                            Button(playlist.name) {
                                                library.addSongToPlaylist(song, playlist: playlist)
                                            }
                                        }
                                    } label: {
                                        Label("添加到歌单", systemImage: "text.badge.plus")
                                    }
                                    Button(role: .destructive) {
                                        library.removeSong(song)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                // 空状态
                if library.songs.isEmpty {
                    emptyStateView
                        .padding(.top, 50)
                }
            }
            .padding(.bottom, 100) // 为迷你播放器留空间
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))

            Text("还没有音乐")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("点击右上角 + 添加本地音乐")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Create Playlist Sheet
    private var createPlaylistSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("歌单名称")) {
                    TextField("输入歌单名称", text: $newPlaylistName)
                }
            }
            .navigationTitle("创建歌单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showCreatePlaylist = false
                        newPlaylistName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        if !newPlaylistName.isEmpty {
                            library.createPlaylist(name: newPlaylistName)
                            newPlaylistName = ""
                            showCreatePlaylist = false
                        }
                    }
                    .disabled(newPlaylistName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions
    private func importFiles() {
        importService.importFiles { songs in
            library.addSongs(songs)
        }
    }

    private func playSong(_ song: Song) {
        player.play(song: song, in: library.songs)
    }
}

// MARK: - Section View
struct SectionView<Content: View>: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                }
            }
            .padding(.horizontal, 15)

            content()
        }
    }
}

// MARK: - Song Card View (水平滚动卡片)
struct SongCardView: View {
    let song: Song
    @ObservedObject private var theme = AppTheme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
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
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 歌曲信息
            Text(song.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(song.displayArtist)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: Song
    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var library = MusicLibraryService.shared
    @ObservedObject private var theme = AppTheme.shared

    var body: some View {
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

            // 歌曲信息
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

            // 时长和收藏
            VStack(alignment: .trailing, spacing: 4) {
                Text(song.formattedDuration)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))

                Button(action: {
                    library.toggleFavorite(song)
                }) {
                    Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(song.isFavorite ? theme.accentColor.color : .white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 15)
    }
}

// MARK: - Playlist Row View
struct PlaylistRowView: View {
    let playlist: Playlist
    @ObservedObject private var theme = AppTheme.shared

    var body: some View {
        HStack(spacing: 12) {
            // 封面
            ZStack {
                if let artwork = playlist.artwork, let uiImage = UIImage(data: artwork) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let firstSongArt = playlist.songs.first?.artwork, let uiImage = UIImage(data: firstSongArt) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [theme.accentColor.color.opacity(0.8), theme.accentColor.color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: playlist.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 歌单信息
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("\(playlist.songCount) 首歌曲")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 15)
    }
}

#Preview {
    LibraryView()
}
