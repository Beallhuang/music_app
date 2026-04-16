//
//  ContentView.swift
//  MusicPlayer
//
//  主视图容器，包含TabBar和迷你播放器
//

import SwiftUI

struct ContentView: View {
    @StateObject private var player = MusicPlayerService.shared
    @StateObject private var theme = AppTheme.shared
    @State private var selectedTab: Tab = .player
    @State private var showFullPlayer = false

    enum Tab: String, CaseIterable {
        case player = "播放"
        case library = "音乐库"
        case remote = "在线"
        case settings = "设置"
        case profile = "我的"

        var icon: String {
            switch self {
            case .player: return "play.circle.fill"
            case .library: return "music.note.list"
            case .remote: return "cloud.fill"
            case .settings: return "gearshape.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // 主内容区域
            Group {
                switch selectedTab {
                case .player:
                    PlayerView()
                case .library:
                    LibraryView()
                case .remote:
                    RemoteLibraryView()
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxHeight: .infinity)

            // 迷你播放器（仅在非播放页面显示）
            if selectedTab != .player && player.currentSong != nil {
                VStack {
                    Spacer()
                    MiniPlayerView()
                        .padding(.bottom, 90)
                        .onTapGesture {
                            selectedTab = .player
                        }
                }
            }

            // 底部标签栏
            VStack {
                Spacer()
                tabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? theme.accentColor.color : .white.opacity(0.5))

                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(selectedTab == tab ? theme.accentColor.color : .white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.bottom, 20)
        .padding(.top, 10)
        .background(
            Color(hex: "1A1A2E").opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

#Preview {
    ContentView()
}
