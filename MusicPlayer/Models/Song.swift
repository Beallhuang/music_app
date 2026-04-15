//
//  Song.swift
//  MusicPlayer
//
//  歌曲数据模型
//

import Foundation
import SwiftUI

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String?
    var album: String?
    var duration: TimeInterval
    var fileURL: URL
    var artwork: Data?
    var dateAdded: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        artist: String? = nil,
        album: String? = nil,
        duration: TimeInterval = 0,
        fileURL: URL,
        artwork: Data? = nil,
        dateAdded: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.artwork = artwork
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
    }

    /// 获取格式化的时长字符串
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 获取艺术家名称（未知艺术家时显示默认文本）
    var displayArtist: String {
        artist ?? "未知艺术家"
    }

    /// 获取专辑名称（未知专辑时显示默认文本）
    var displayAlbum: String {
        album ?? "未知专辑"
    }

    /// 获取封面图片
    var artworkImage: Image? {
        guard let data = artwork, let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, duration, fileURL, artwork, dateAdded, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
        artwork = try container.decodeIfPresent(Data.self, forKey: .artwork)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
