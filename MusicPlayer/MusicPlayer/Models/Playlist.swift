//
//  Playlist.swift
//  MusicPlayer
//
//  歌单数据模型
//

import Foundation
import SwiftUI

struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var songs: [Song]
    var artwork: Data?
    var dateCreated: Date
    var dateModified: Date
    var icon: String // SF Symbol 名称

    init(
        id: UUID = UUID(),
        name: String,
        songs: [Song] = [],
        artwork: Data? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        icon: String = "music.note.list"
    ) {
        self.id = id
        self.name = name
        self.songs = songs
        self.artwork = artwork
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.icon = icon
    }

    /// 歌曲数量
    var songCount: Int {
        songs.count
    }

    /// 总时长
    var totalDuration: TimeInterval {
        songs.reduce(0) { $0 + $1.duration }
    }

    /// 格式化的总时长
    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        }
        return String(format: "%d分钟", minutes)
    }

    /// 获取封面图片
    var artworkImage: Image? {
        if let data = artwork, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return songs.first?.artworkImage
    }

    /// 添加歌曲
    mutating func addSong(_ song: Song) {
        if !songs.contains(where: { $0.id == song.id }) {
            songs.append(song)
            dateModified = Date()
        }
    }

    /// 移除歌曲
    mutating func removeSong(at index: Int) {
        guard songs.indices.contains(index) else { return }
        songs.remove(at: index)
        dateModified = Date()
    }

    /// 移除歌曲（通过ID）
    mutating func removeSong(withId id: UUID) {
        songs.removeAll { $0.id == id }
        dateModified = Date()
    }
}

// MARK: - 预设歌单图标
extension Playlist {
    static let playlistIcons = [
        "music.note.list",
        "heart.fill",
        "star.fill",
        "flame.fill",
        "moon.fill",
        "sun.max.fill",
        "cloud.fill",
        "bolt.fill",
        "leaf.fill",
        "guitar",
        "headphones",
        "mic.fill"
    ]
}
