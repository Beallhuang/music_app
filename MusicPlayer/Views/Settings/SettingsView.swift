//
//  SettingsView.swift
//  MusicPlayer
//
//  设置页面
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var theme = AppTheme.shared
    @StateObject private var library = MusicLibraryService.shared
    @StateObject private var remoteLibrary = RemoteLibraryService.shared

    @State private var showServerConfig = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // 播放设置
                        SettingsGroupView(title: "播放设置") {
                            SettingsStepperView(title: "跳过间隔", value: "\(theme.skipInterval)秒")
                            SettingsToggleView(title: "淡入淡出", isOn: $theme.fadeInOut)
                            SettingsToggleView(title: "后台播放", isOn: $theme.backgroundPlay)
                        }

                        // 歌词设置
                        SettingsGroupView(title: "歌词设置") {
                            SettingsToggleView(title: "显示歌词", isOn: $theme.showLyrics)
                            SettingsPickerView(title: "字体大小", value: theme.lyricsFontSize.rawValue)
                            SettingsPickerView(title: "歌词来源", value: "本地")
                            SettingsToggleView(title: "翻译歌词", isOn: $theme.showTranslation)
                        }

                        // 外观设置
                        SettingsGroupView(title: "外观设置") {
                            SettingsPickerView(title: "主题模式", value: theme.themeMode.rawValue)
                            SettingsColorPickerView(title: "强调色", selectedColor: $theme.accentColor)
                            SettingsToggleView(title: "专辑封面模糊背景", isOn: $theme.albumArtBlurBackground)
                        }

                        // 存储
                        SettingsGroupView(title: "存储") {
                            SettingsValueView(title: "音乐缓存", value: calculateCacheSize())
                            Button(action: { remoteLibrary.removeAllCache() }) {
                                HStack {
                                    Text("清除音乐缓存")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("清除")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "FF6B6B"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            SettingsValueView(title: "歌词缓存", value: calculateLyricCacheSize())
                            Button(action: { remoteLibrary.removeAllLyricCache() }) {
                                HStack {
                                    Text("清除歌词缓存")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("清除")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "FF6B6B"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                        }

                        // 在线音乐
                        SettingsGroupView(title: "在线音乐") {
                            Button(action: { showServerConfig = true }) {
                                HStack {
                                    Text("服务器地址")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(remoteLibrary.jsonURL.isEmpty ? "未配置" : remoteLibrary.jsonURL)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: 160, alignment: .trailing)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                        }

                        // 关于
                        SettingsGroupView(title: "关于") {
                            SettingsValueView(title: "版本", value: "1.0.0")
                            SettingsLinkView(title: "开源许可")
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("设置")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showServerConfig) {
                RemoteConfigView()
            }
        }
    }

    // MARK: - Helper Methods
    private func calculateCacheSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: remoteLibrary.cacheSize)
    }

    private func calculateLyricCacheSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: remoteLibrary.lyricCacheSize)
    }
}

// MARK: - Settings Group View
struct SettingsGroupView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 15)
        }
    }
}

// MARK: - Settings Toggle View
struct SettingsToggleView: View {
    let title: String
    @Binding var isOn: Bool
    @ObservedObject private var theme = AppTheme.shared

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accentColor.color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 20)
    }
}

// MARK: - Settings Picker View
struct SettingsPickerView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 5) {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 20)
    }
}

// MARK: - Settings Value View
struct SettingsValueView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Stepper View
struct SettingsStepperView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 5) {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 20)
    }
}

// MARK: - Settings Link View
struct SettingsLinkView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Color Picker View
struct SettingsColorPickerView: View {
    let title: String
    @Binding var selectedColor: AccentColor

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 20, height: 20)

                Text(selectedColor.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 20)
    }
}

#Preview {
    SettingsView()
}
