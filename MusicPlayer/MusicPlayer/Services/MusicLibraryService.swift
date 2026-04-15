//
//  MusicLibraryService.swift
//  MusicPlayer
//
//  音乐库数据管理服务
//

import Foundation
import Combine

/// 音乐库服务
class MusicLibraryService: ObservableObject {
    static let shared = MusicLibraryService()

    @Published var songs: [Song] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var playlists: [Playlist] = []
    @Published var recentlyPlayed: [Song] = []
    @Published var favorites: [Song] = []

    private let songsKey = "savedSongs"
    private let playlistsKey = "savedPlaylists"
    private let recentlyPlayedKey = "recentlyPlayed"
    private let favoritesKey = "favorites"

    private init() {
        loadData()
        createDefaultPlaylists()
    }

    // MARK: - Load/Save Data
    private func loadData() {
        // 加载歌曲
        if let data = UserDefaults.standard.data(forKey: songsKey),
           let decodedSongs = try? JSONDecoder().decode([Song].self, from: data) {
            songs = decodedSongs
        }

        // 加载歌单
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decodedPlaylists = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decodedPlaylists
        }

        // 加载最近播放
        if let data = UserDefaults.standard.data(forKey: recentlyPlayedKey),
           let decodedSongs = try? JSONDecoder().decode([Song].self, from: data) {
            recentlyPlayed = decodedSongs
        }

        // 加载收藏
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decodedSongs = try? JSONDecoder().decode([Song].self, from: data) {
            favorites = decodedSongs
        }

        // 重新组织数据
        organizeData()
    }

    private func saveData() {
        // 保存歌曲
        if let encoded = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(encoded, forKey: songsKey)
        }

        // 保存歌单
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }

        // 保存最近播放
        if let encoded = try? JSONEncoder().encode(recentlyPlayed) {
            UserDefaults.standard.set(encoded, forKey: recentlyPlayedKey)
        }

        // 保存收藏
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }

    // MARK: - Organize Data
    private func organizeData() {
        // 按专辑分组
        var albumDict: [String: Album] = {}
        for song in songs {
            let albumTitle = song.album ?? "未知专辑"
            if var album = albumDict[albumTitle] {
                album.songs.append(song)
                albumDict[albumTitle] = album
            } else {
                albumDict[albumTitle] = Album(
                    title: albumTitle,
                    artist: song.artist,
                    artwork: song.artwork,
                    songs: [song]
                )
            }
        }
        albums = Array(albumDict.values)

        // 按艺术家分组
        var artistDict: [String: Artist] = {}
        for song in songs {
            let artistName = song.artist ?? "未知艺术家"
            if var artist = artistDict[artistName] {
                artist.songs.append(song)
                artistDict[artistName] = artist
            } else {
                artistDict[artistName] = Artist(
                    name: artistName,
                    songs: [song]
                )
            }
        }

        // 将专辑添加到艺术家
        for album in albums {
            let artistName = album.artist ?? "未知艺术家"
            if var artist = artistDict[artistName] {
                artist.albums.append(album)
                artistDict[artistName] = artist
            }
        }
        artists = Array(artistDict.values)
    }

    // MARK: - Default Playlists
    private func createDefaultPlaylists() {
        if playlists.isEmpty {
            let favoritesPlaylist = Playlist(
                name: "我喜欢的音乐",
                songs: favorites,
                icon: "heart.fill"
            )
            playlists.append(favoritesPlaylist)
            saveData()
        }
    }

    // MARK: - Add/Remove Songs
    func addSong(_ song: Song) {
        if !songs.contains(where: { $0.id == song.id }) {
            songs.append(song)
            organizeData()
            saveData()
        }
    }

    func addSongs(_ newSongs: [Song]) {
        for song in newSongs {
            if !songs.contains(where: { $0.id == song.id }) {
                songs.append(song)
            }
        }
        organizeData()
        saveData()
    }

    func removeSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        recentlyPlayed.removeAll { $0.id == song.id }
        favorites.removeAll { $0.id == song.id }

        // 从歌单中移除
        for i in playlists.indices {
            playlists[i].removeSong(withId: song.id)
        }

        organizeData()
        saveData()
    }

    func removeSong(at index: Int) {
        guard songs.indices.contains(index) else { return }
        let song = songs[index]
        removeSong(song)
    }

    // MARK: - Favorites
    func addToFavorites(_ song: Song) {
        if !favorites.contains(where: { $0.id == song.id }) {
            favorites.append(song)

            // 更新歌曲状态
            if let index = songs.firstIndex(where: { $0.id == song.id }) {
                songs[index].isFavorite = true
            }

            // 更新"我喜欢的音乐"歌单
            if let index = playlists.firstIndex(where: { $0.name == "我喜欢的音乐" }) {
                playlists[index].addSong(song)
            }

            saveData()
        }
    }

    func removeFromFavorites(_ song: Song) {
        favorites.removeAll { $0.id == song.id }

        // 更新歌曲状态
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].isFavorite = false
        }

        // 更新"我喜欢的音乐"歌单
        if let index = playlists.firstIndex(where: { $0.name == "我喜欢的音乐" }) {
            playlists[index].removeSong(withId: song.id)
        }

        saveData()
    }

    func toggleFavorite(_ song: Song) {
        if favorites.contains(where: { $0.id == song.id }) {
            removeFromFavorites(song)
        } else {
            addToFavorites(song)
        }
    }

    // MARK: - Recently Played
    func addToRecentlyPlayed(_ song: Song) {
        // 先移除已有的
        recentlyPlayed.removeAll { $0.id == song.id }
        // 添加到最前面
        recentlyPlayed.insert(song, at: 0)
        // 最多保留50条
        if recentlyPlayed.count > 50 {
            recentlyPlayed = Array(recentlyPlayed.prefix(50))
        }
        saveData()
    }

    // MARK: - Playlists
    func createPlaylist(name: String, icon: String = "music.note.list") {
        let playlist = Playlist(name: name, icon: icon)
        playlists.append(playlist)
        saveData()
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        saveData()
    }

    func renamePlaylist(_ playlist: Playlist, newName: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].name = newName
            saveData()
        }
    }

    func addSongToPlaylist(_ song: Song, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].addSong(song)
            saveData()
        }
    }

    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].removeSong(withId: song.id)
            saveData()
        }
    }

    // MARK: - Search
    func searchSongs(query: String) -> [Song] {
        guard !query.isEmpty else { return songs }
        let lowercasedQuery = query.lowercased()
        return songs.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            ($0.artist?.lowercased().contains(lowercasedQuery) ?? false) ||
            ($0.album?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    func searchAlbums(query: String) -> [Album] {
        guard !query.isEmpty else { return albums }
        let lowercasedQuery = query.lowercased()
        return albums.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            ($0.artist?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    func searchArtists(query: String) -> [Artist] {
        guard !query.isEmpty else { return artists }
        let lowercasedQuery = query.lowercased()
        return artists.filter {
            $0.name.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Statistics
    var totalSongCount: Int { songs.count }
    var totalAlbumCount: Int { albums.count }
    var totalArtistCount: Int { artists.count }
    var totalPlaylistCount: Int { playlists.count }

    var recentlyAddedSongs: [Song] {
        songs.sorted { $0.dateAdded > $1.dateAdded }.prefix(20).map { $0 }
    }
}