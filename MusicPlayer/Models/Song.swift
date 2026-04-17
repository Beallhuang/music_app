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
        case id, title, artist, album, duration, fileURL, relativePath, artwork, dateAdded, isFavorite
    }

    /// 计算相对于 Documents 目录的相对路径
    private var relativePath: String? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
            return nil
        }
        let filePath = fileURL.path
        if filePath.hasPrefix(documentsPath) {
            return String(filePath.dropFirst(documentsPath.count))
        }
        return nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(artist, forKey: .artist)
        try container.encodeIfPresent(album, forKey: .album)
        try container.encode(duration, forKey: .duration)
        try container.encode(fileURL, forKey: .fileURL)
        try container.encodeIfPresent(relativePath, forKey: .relativePath)
        try container.encodeIfPresent(artwork, forKey: .artwork)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(isFavorite, forKey: .isFavorite)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        artwork = try container.decodeIfPresent(Data.self, forKey: .artwork)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false

        // 优先用相对路径拼接当前 Documents 目录，解决 iOS 沙盒容器 UUID 变化问题
        let savedURL = try container.decode(URL.self, forKey: .fileURL)
        if let relPath = try container.decodeIfPresent(String.self, forKey: .relativePath),
           let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let reconstructed = documentsURL.appendingPathComponent(relPath)
            if FileManager.default.fileExists(atPath: reconstructed.path) {
                fileURL = reconstructed
            } else {
                fileURL = savedURL
            }
        } else {
            fileURL = savedURL
        }
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
