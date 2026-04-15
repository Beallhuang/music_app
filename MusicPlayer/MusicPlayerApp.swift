//
//  MusicPlayerApp.swift
//  MusicPlayer
//
//  应用程序入口
//

import SwiftUI

@main
struct MusicPlayerApp: App {
    @StateObject private var theme = AppTheme.shared
    @StateObject private var library = MusicLibraryService.shared

    init() {
        // 配置外观
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(getColorScheme())
                .environmentObject(theme)
                .environmentObject(library)
        }
    }

    // MARK: - Setup
    private func setupAppearance() {
        // 配置导航栏外观
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color(hex: "1A1A2E"))
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        // 配置表格外观
        UITableView.appearance().backgroundColor = UIColor.clear
        UITableViewCell.appearance().backgroundColor = UIColor.clear

        // 配置开关外观
        UISwitch.appearance().onTintColor = UIColor(Color(hex: "FF6B6B"))
    }

    private func getColorScheme() -> ColorScheme? {
        switch theme.themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}
