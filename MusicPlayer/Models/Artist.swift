//
//  Artist.swift
//  MusicPlayer
//
//  艺术家数据模型
//

import Foundation
import SwiftUI

struct Artist: Identifiable, Codable {
    let id: UUID
    var name: String
    var albums: [Album]
    var songs: [Song]
    var artwork: Data?

    init(
        id: UUID = UUID(),
        name: String,
        albums: [Album] = [],
        songs: [Song] = [],
        artwork: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.albums = albums
        self.songs = songs
        self.artwork = artwork
    }

    /// 专辑数量
    var albumCount: Int {
        albums.count
    }

    /// 歌曲数量
    var songCount: Int {
        songs.count
    }

    /// 获取封面图片（从第一个专辑或歌曲获取）
    var artworkImage: Image? {
        if let data = artwork, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return albums.first?.artworkImage ?? songs.first?.artworkImage
    }
}
