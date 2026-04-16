//
//  LyricParserService.swift
//  MusicPlayer
//
//  歌词文件解析服务
//

import Foundation

/// 歌词解析服务
class LyricParserService {
    static let shared = LyricParserService()

    /// 解析LRC歌词文件
    func parseLrcFile(from url: URL) -> Lyrics? {
        guard url.pathExtension.lowercased() == "lrc" else { return nil }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return parseLrcContent(content)
        } catch {
            // 尝试 GBK 编码（常见于中文歌词文件）
            let gbkEncoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(gbkEncoding)
            let swiftEncoding = String.Encoding(rawValue: nsEncoding)
            if let content = try? String(contentsOf: url, encoding: swiftEncoding) {
                return parseLrcContent(content)
            }
            print("Failed to read lyric file: \(error)")
            return nil
        }
    }

    /// 解析LRC歌词内容
    func parseLrcContent(_ content: String) -> Lyrics {
        var lines: [LyricLine] = []
        var metadata: [String: String] = [:]

        let contentLines = content.split(separator: "\n", omittingEmptySubsequences: false)

        for line in contentLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // 空行跳过
            if trimmedLine.isEmpty { continue }

            // 解析元数据 [ti:标题] [ar:艺术家] [al:专辑]
            if let meta = parseMetadata(trimmedLine) {
                metadata[meta.key] = meta.value
                continue
            }

            // 解析歌词行 [mm:ss.xx]歌词内容 或 [mm:ss]歌词内容
            if trimmedLine.hasPrefix("[") {
                if let lyricLine = parseTimeTag(trimmedLine) {
                    lines.append(lyricLine)
                }
            }
        }

        // 按时间排序
        lines.sort { $0.time < $1.time }

        return Lyrics(lines: lines, metadata: metadata)
    }

    /// 解析时间标签行
    private func parseTimeTag(_ line: String) -> LyricLine? {
        // 格式: [mm:ss.xx]歌词内容 或 [mm:ss.xxx]歌词内容
        // 也支持 [mm:ss]歌词内容

        let pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2,3})\\](.*)"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else {
            // 尝试简化格式 [mm:ss]
            let simplePattern = "\\[(\\d{2}):(\\d{2})\\](.*)"
            guard let simpleRegex = try? NSRegularExpression(pattern: simplePattern) else { return nil }
            guard let simpleMatch = simpleRegex.firstMatch(in: line, range: range) else { return nil }

            let minuteRange = Range(simpleMatch.range(at: 1), in: line)!
            let secondRange = Range(simpleMatch.range(at: 2), in: line)!
            let textRange = Range(simpleMatch.range(at: 3), in: line)!

            let minutes = Int(line[minuteRange]) ?? 0
            let seconds = Int(line[secondRange]) ?? 0
            let text = String(line[textRange]).trimmingCharacters(in: .whitespaces)

            if text.isEmpty { return nil }

            return LyricLine(time: Double(minutes * 60 + seconds), text: text)
        }

        let minuteRange = Range(match.range(at: 1), in: line)!
        let secondRange = Range(match.range(at: 2), in: line)!
        let millisecondRange = Range(match.range(at: 3), in: line)!
        let textRange = Range(match.range(at: 4), in: line)!

        let minutes = Int(line[minuteRange]) ?? 0
        let seconds = Int(line[secondRange]) ?? 0
        let millisecondsStr = String(line[millisecondRange])
        let milliseconds = Double(millisecondsStr) ?? 0

        // 根据毫秒位数调整
        let msMultiplier = millisecondsStr.count == 2 ? 10 : 1000

        let text = String(line[textRange]).trimmingCharacters(in: .whitespaces)

        if text.isEmpty { return nil }

        let time = Double(minutes * 60 + seconds) + milliseconds / Double(msMultiplier)

        return LyricLine(time: time, text: text)
    }

    /// 解析元数据标签
    private func parseMetadata(_ line: String) -> (key: String, value: String)? {
        // 格式: [ti:标题] [ar:艺术家] [al:专辑] [by:歌词作者]
        // 元数据标签的特征是 [key:value] 其中 key 是非数字开头的字母
        let pattern = "^\\[([a-zA-Z]+):(.+?)\\]$"

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        let keyRange = Range(match.range(at: 1), in: line)!
        let valueRange = Range(match.range(at: 2), in: line)!

        let key = String(line[keyRange])
        let value = String(line[valueRange])

        return (key, value)
    }

    /// 根据歌曲文件查找歌词文件
    func findLyricFile(for song: Song) -> URL? {
        let songDirectory = song.fileURL.deletingLastPathComponent()
        let songFileName = song.fileURL.deletingPathExtension().lastPathComponent

        // 尝试匹配同名歌词文件
        let lrcURL = songDirectory.appendingPathComponent("\(songFileName).lrc")
        if FileManager.default.fileExists(atPath: lrcURL.path) {
            return lrcURL
        }

        // 尝试在Lyrics目录查找
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let lyricsDirectory = documentsDirectory.appendingPathComponent("Lyrics", isDirectory: true)

        if FileManager.default.fileExists(atPath: lyricsDirectory.path) {
            let lrcURL2 = lyricsDirectory.appendingPathComponent("\(songFileName).lrc")
            if FileManager.default.fileExists(atPath: lrcURL2.path) {
                return lrcURL2
            }

            // 尝试用歌曲标题匹配
            let titleLrcURL = lyricsDirectory.appendingPathComponent("\(song.title).lrc")
            if FileManager.default.fileExists(atPath: titleLrcURL.path) {
                return titleLrcURL
            }
        }

        return nil
    }

    /// 加载歌曲的歌词
    func loadLyrics(for song: Song) -> Lyrics? {
        guard let lrcURL = findLyricFile(for: song) else { return nil }
        return parseLrcFile(from: lrcURL)
    }

    /// 解析远程歌词内容（异步，已由 RemoteLibraryService 下载为字符串）
    func loadRemoteLyrics(content: String) -> Lyrics? {
        let lyrics = parseLrcContent(content)
        return lyrics.lines.isEmpty ? nil : lyrics
    }
}