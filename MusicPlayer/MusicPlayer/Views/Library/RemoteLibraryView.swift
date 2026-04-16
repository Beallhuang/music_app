//
//  RemoteLibraryView.swift
//  MusicPlayer
//
//  远程服务器音乐库浏览页面
//

import SwiftUI

struct RemoteLibraryView: View {
    @StateObject private var remoteLibrary = RemoteLibraryService.shared
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var theme = AppTheme.shared

    @State private var searchText = ""
    @State private var showServerConfig = false

    var filteredSongs: [RemoteSong] {
        if searchText.isEmpty { return remoteLibrary.songs }
        return remoteLibrary.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                searchBarView

                if remoteLibrary.serverURL.isEmpty {
                    emptyServerView
                } else if remoteLibrary.isLoading {
                    loadingView
                } else if let error = remoteLibrary.errorMessage {
                    errorView(message: error)
                } else if remoteLibrary.songs.isEmpty {
                    emptySongsView
                } else {
                    songListView
                }
            }
        }
        .sheet(isPresented: $showServerConfig) {
            ServerConfigView()
        }
        .onAppear {
            // 有服务器地址但列表为空时自动扫描
            if !remoteLibrary.serverURL.isEmpty && remoteLibrary.songs.isEmpty && !remoteLibrary.isLoading {
                Task { await remoteLibrary.scanServer() }
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("在线音乐")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 刷新按钮
            if !remoteLibrary.serverURL.isEmpty {
                Button(action: {
                    Task { await remoteLibrary.scanServer() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            // 服务器配置按钮
            Button(action: { showServerConfig = true }) {
                Image(systemName: "server.rack")
                    .font(.system(size: 16, weight: .medium))
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

            TextField("搜索歌曲、艺术家...", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    // MARK: - Song List
    private var songListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredSongs) { song in
                    RemoteSongRowView(song: song)
                        .onTapGesture {
                            playSong(song)
                        }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty / Loading States
    private var emptyServerView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            Text("未配置服务器")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text("点击右上角配置服务器地址")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 15) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("正在扫描服务器...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 10)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button(action: {
                Task { await remoteLibrary.scanServer() }
            }) {
                Text("重试")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(theme.accentColor.color)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var emptySongsView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            Text("服务器上没有找到音乐文件")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text("支持 mp3、m4a、flac、wav、aac 格式")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        }
    }

    // MARK: - Actions
    private func playSong(_ remoteSong: RemoteSong) {
        let song = remoteSong.toSong()
        let playlist = filteredSongs.map { $0.toSong() }
        player.play(song: song, in: playlist)
    }
}

// MARK: - Remote Song Row
struct RemoteSongRowView: View {
    let song: RemoteSong
    @StateObject private var remoteLibrary = RemoteLibraryService.shared
    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var theme = AppTheme.shared

    var downloadState: DownloadState? {
        remoteLibrary.downloadStates[song.id]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 封面占位
            ZStack {
                LinearGradient(
                    colors: [theme.accentColor.color.opacity(0.8), theme.accentColor.color.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(player.currentSong?.id == song.id ? theme.accentColor.color : .white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(song.artist ?? "未知艺术家")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)

                    if song.lyricURL != nil {
                        Image(systemName: "text.quote")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }

            Spacer()

            // 下载/缓存状态按钮
            downloadButton
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 15)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var downloadButton: some View {
        if song.isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green.opacity(0.8))
        } else if case .downloading(let progress) = downloadState {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 24, height: 24)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.accentColor.color, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                Button(action: { remoteLibrary.cancelDownload(song) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        } else {
            Button(action: { remoteLibrary.downloadSong(song) }) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Server Config View
struct ServerConfigView: View {
    @StateObject private var remoteLibrary = RemoteLibraryService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var urlInput: String = ""
    @ObservedObject private var theme = AppTheme.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 25) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("服务器地址")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .padding(.horizontal, 5)

                        TextField("http://192.168.1.100:8080/music/", text: $urlInput)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(14)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("输入 HTTP 文件服务器的根目录地址，应用会自动扫描其中的音频文件（mp3、m4a、flac、wav 等）和同名 lrc 歌词文件。")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 5)
                    }
                    .padding(.horizontal, 20)

                    Button(action: {
                        // 确保 URL 以 / 结尾
                        var url = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !url.isEmpty && !url.hasSuffix("/") { url += "/" }
                        remoteLibrary.serverURL = url
                        dismiss()
                        if !url.isEmpty {
                            Task { await remoteLibrary.scanServer() }
                        }
                    }) {
                        Text("保存并扫描")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(urlInput.isEmpty ? Color.white.opacity(0.2) : theme.accentColor.color)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(urlInput.isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationTitle("服务器配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear {
            urlInput = remoteLibrary.serverURL
        }
    }
}
