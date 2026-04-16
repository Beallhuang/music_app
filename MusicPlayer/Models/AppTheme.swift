//
//  AppTheme.swift
//  MusicPlayer
//
//  应用主题配置
//

import SwiftUI

/// 主题模式
enum ThemeMode: String, CaseIterable, Codable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// 强调色
enum AccentColor: String, CaseIterable, Codable {
    case coral = "珊瑚红"
    case ocean = "海洋蓝"
    case forest = "森林绿"
    case sunset = "日落橙"
    case lavender = "薰衣草紫"
    case rose = "玫瑰粉"

    var color: Color {
        switch self {
        case .coral: return Color(hex: "FF6B6B")
        case .ocean: return Color(hex: "4ECDC4")
        case .forest: return Color(hex: "2ECC71")
        case .sunset: return Color(hex: "FF8E53")
        case .lavender: return Color(hex: "9B59B6")
        case .rose: return Color(hex: "E91E63")
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// 主题管理器
class AppTheme: ObservableObject {
    static let shared = AppTheme()

    @Published var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }

    @Published var accentColor: AccentColor {
        didSet { UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor") }
    }

    @Published var showLyrics: Bool {
        didSet { UserDefaults.standard.set(showLyrics, forKey: "showLyrics") }
    }

    @Published var lyricsFontSize: LyricsFontSize {
        didSet { UserDefaults.standard.set(lyricsFontSize.rawValue, forKey: "lyricsFontSize") }
    }

    @Published var showTranslation: Bool {
        didSet { UserDefaults.standard.set(showTranslation, forKey: "showTranslation") }
    }

    @Published var albumArtBlurBackground: Bool {
        didSet { UserDefaults.standard.set(albumArtBlurBackground, forKey: "albumArtBlurBackground") }
    }

    @Published var fadeInOut: Bool {
        didSet { UserDefaults.standard.set(fadeInOut, forKey: "fadeInOut") }
    }

    @Published var backgroundPlay: Bool {
        didSet { UserDefaults.standard.set(backgroundPlay, forKey: "backgroundPlay") }
    }

    @Published var skipInterval: Int {
        didSet { UserDefaults.standard.set(skipInterval, forKey: "skipInterval") }
    }

    private init() {
        self.themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "") ?? .system
        self.accentColor = AccentColor(rawValue: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? .coral
        self.showLyrics = UserDefaults.standard.object(forKey: "showLyrics") as? Bool ?? true
        self.lyricsFontSize = LyricsFontSize(rawValue: UserDefaults.standard.string(forKey: "lyricsFontSize") ?? "") ?? .medium
        self.showTranslation = UserDefaults.standard.object(forKey: "showTranslation") as? Bool ?? true
        self.albumArtBlurBackground = UserDefaults.standard.object(forKey: "albumArtBlurBackground") as? Bool ?? true
        self.fadeInOut = UserDefaults.standard.object(forKey: "fadeInOut") as? Bool ?? false
        self.backgroundPlay = UserDefaults.standard.object(forKey: "backgroundPlay") as? Bool ?? true
        self.skipInterval = UserDefaults.standard.object(forKey: "skipInterval") as? Int ?? 10
    }
}

/// 歌词字体大小
enum LyricsFontSize: String, CaseIterable, Codable {
    case small = "小"
    case medium = "中等"
    case large = "大"

    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }

    var activeSize: CGFloat {
        size + 2
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 颜色常量
extension Color {
    static let appBackground = Color(hex: "1A1A2E")
    static let appSecondaryBackground = Color(hex: "16213E")
    static let appCardBackground = Color(hex: "252542")
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(hex: "888888")
    static let appDivider = Color(hex: "333355")
}

