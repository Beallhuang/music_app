//
//  Album.swift
//  MusicPlayer
//
//  专辑数据模型
//

import Foundation
import SwiftUI

struct Album: Identifiable, Codable {
    let id: UUID
    var title: String
    var artist: String?
    var artwork: Data?
    var songs: [Song]
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String? = nil,
        artwork: Data? = nil,
        songs: [Song] = [],
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.songs = songs
        self.dateAdded = dateAdded
    }

    /// 专辑总时长
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

    /// 歌曲数量
    var songCount: Int {
        songs.count
    }

    /// 获取封面图片
    var artworkImage: Image? {
        guard let data = artwork, let uiImage = UIImage(data: data) else {
            // 尝试从第一首歌获取封面
            return songs.first?.artworkImage
        }
        return Image(uiImage: uiImage)
    }
}
