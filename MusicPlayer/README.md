# MusicPlayer

一个现代化的 iOS 音乐播放器应用，使用 SwiftUI 开发。

## 功能特性

- 🎵 **本地音乐导入** - 支持导入 MP3、M4A、FLAC、WAV、AAC 格式
- 📝 **歌词显示** - 支持 .lrc 歌词文件解析，实时滚动显示
- 🎨 **现代化 UI** - 深色主题，毛玻璃效果，流畅动画
- 💾 **音乐库管理** - 歌曲分类、歌单创建、收藏功能
- 🎛️ **播放控制** - 播放/暂停、上下曲、进度调整
- 🔀 **播放模式** - 随机播放、单曲循环、列表循环
- 🎤 **后台播放** - 支持后台播放和锁屏控制
- ⏯️ **迷你播放器** - 底部悬浮迷你播放器

## 项目结构

```
MusicPlayer/
├── Models/              # 数据模型
│   ├── Song.swift       # 歌曲模型
│   ├── Album.swift      # 专辑模型
│   ├── Artist.swift     # 艺术家模型
│   ├── Playlist.swift   # 歌单模型
│   ├── LyricLine.swift  # 歌词模型
│   └── AppTheme.swift   # 主题配置
├── Services/            # 服务层
│   ├── MusicPlayerService.swift    # 播放服务
│   ├── MusicLibraryService.swift   # 音乐库服务
│   ├── FileImportService.swift     # 文件导入服务
│   └── LyricParserService.swift    # 歌词解析服务
├── Views/               # 视图层
│   ├── Player/          # 播放器视图
│   ├── Library/         # 音乐库视图
│   ├── Settings/        # 设置视图
│   └── Profile/         # 个人中心视图
├── ContentView.swift    # 主视图容器
├── MusicPlayerApp.swift # 应用入口
└── Info.plist          # 应用配置
```

## 技术栈

- **UI 框架**: SwiftUI
- **音频播放**: AVFoundation
- **后台播放**: AVAudioSession + MediaPlayer
- **数据存储**: UserDefaults + Codable
- **最低版本**: iOS 15.0

## 使用说明

### 导入音乐
1. 打开应用，进入「音乐库」页面
2. 点击右上角「+」按钮
3. 选择本地音乐文件导入
4. 支持多选和批量导入

### 歌词使用
- 将 .lrc 歌词文件放在与音乐文件相同的目录
- 歌词文件名需与音乐文件名相同
- 应用会自动匹配并显示歌词

### 创建歌单
1. 进入「音乐库」→「歌单」标签
2. 点击「创建新歌单」
3. 输入歌单名称
4. 长按歌曲可添加到歌单

## 开发环境

- Xcode 14.0+
- Swift 5.7+
- iOS 15.0+

## 安装

1. 克隆项目
```bash
git clone <repository-url>
```

2. 使用 Xcode 打开 `MusicPlayer.xcodeproj`

3. 选择目标设备运行

## 许可证

MIT License
