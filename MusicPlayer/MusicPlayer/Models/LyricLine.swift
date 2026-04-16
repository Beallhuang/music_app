//
//  LyricLine.swift
//  MusicPlayer
//
//  歌词数据模型
//

import Foundation

/// 单行歌词
struct LyricLine: Identifiable, Codable {
    let id: UUID
    let time: TimeInterval // 时间戳（秒）
    let text: String // 歌词文本
    var translation: String? // 翻译文本

    init(id: UUID = UUID(), time: TimeInterval, text: String, translation: String? = nil) {
        self.id = id
        self.time = time
        self.text = text
        self.translation = translation
    }

    /// 格式化的时间字符串
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// 歌词文件
struct Lyrics: Codable {
    var lines: [LyricLine]
    var metadata: [String: String] // 歌词元数据（如艺术家、专辑等）

    init(lines: [LyricLine] = [], metadata: [String: String] = [:]) {
        self.lines = lines
        self.metadata = metadata
    }

    /// 是否为空
    var isEmpty: Bool {
        lines.isEmpty
    }

    /// 获取指定时间对应的歌词行索引
    func index(for time: TimeInterval) -> Int? {
        // 找到最后一个时间小于等于当前时间的歌词行
        for i in (0..<lines.count).reversed() {
            if lines[i].time <= time {
                return i
            }
        }
        return nil
    }

    /// 获取指定时间对应的歌词行
    func line(for time: TimeInterval) -> LyricLine? {
        guard let index = index(for: time) else { return nil }
        return lines[index]
    }

    /// 获取指定时间前后几行的歌词（用于滚动显示）
    func lines(around time: TimeInterval, count: Int = 5) -> [LyricLine] {
        guard let centerIndex = index(for: time) else {
            return Array(lines.prefix(count))
        }

        let startIndex = max(0, centerIndex - count / 2)
        let endIndex = min(lines.count, startIndex + count)

        return Array(lines[startIndex..<endIndex])
    }
}

// MARK: - 歌词解析错误
enum LyricParseError: Error, LocalizedError {
    case invalidFormat
    case invalidTimeFormat
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "歌词格式无效"
        case .invalidTimeFormat:
            return "时间格式无效"
        case .emptyContent:
            return "歌词内容为空"
        }
    }
}
