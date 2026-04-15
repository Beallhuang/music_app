# 🎵 MusicPlayer - iOS 音乐播放器

一个现代化的 iOS 本地音乐播放器，使用 SwiftUI 开发，支持导入本地音乐和歌词显示。

![Platform](https://img.shields.io/badge/Platform-iOS%2015%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.7-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 功能特性

### 🎶 音乐播放
- 支持导入本地音乐文件（MP3、M4A、FLAC、WAV、AAC）
- 播放控制：播放/暂停、上下曲、进度拖拽
- 播放模式：随机播放、单曲循环、列表循环
- 后台播放支持，锁屏控制

### 📝 歌词显示
- 支持 .lrc 歌词文件解析
- 实时同步滚动显示
- 当前行高亮效果
- 支持翻译歌词显示

### 🎨 现代化 UI
- 深色主题设计
- 毛玻璃效果
- 流畅动画过渡
- 可自定义强调色（6种颜色可选）

### 📚 音乐库管理
- 歌曲分类（全部、专辑、艺术家、歌单）
- 创建自定义歌单
- 收藏功能
- 最近播放记录
- 搜索功能

### ⚙️ 个性化设置
- 深浅色主题切换
- 歌词字体大小调整
- 专辑封面模糊背景效果

---

## 📱 界面预览

| 播放界面 | 音乐库 | 设置 |
|:---:|:---:|:---:|
| 播放界面 | 歌曲列表 | 主题设置 |

---

## 🚀 安装方式

### 方式一：免费签名安装（推荐）

使用 Apple ID 免费签名安装，详见 [免费安装指南](FREE_INSTALL_GUIDE.md)

**简要步骤：**
1. 上传代码到 GitHub
2. GitHub Actions 自动编译生成 IPA
3. 下载 [Sideloadly](https://sideloadly.io/)
4. 连接 iPhone，用 Apple ID 签名安装
5. 在设置中信任开发者

⚠️ **注意**：免费签名每 7 天需重新签名一次

### 方式二：开发者账号

如果你有 Apple Developer Program 账号（¥688/年）：
1. 用 Xcode 打开项目
2. 配置你的 Team 和 Bundle ID
3. 直接安装到设备

---

## 🛠️ 开发环境

| 要求 | 版本 |
|------|------|
| Xcode | 14.0+ |
| Swift | 5.7+ |
| iOS Deployment Target | 15.0+ |
| macOS | 12.0+（开发需要） |

---

## 📁 项目结构

```
MusicPlayer/
├── Models/                      # 数据模型层
│   ├── Song.swift              # 歌曲模型
│   ├── Album.swift             # 专辑模型
│   ├── Artist.swift            # 艺术家模型
│   ├── Playlist.swift          # 歌单模型
│   ├── LyricLine.swift         # 歌词模型
│   └── AppTheme.swift          # 主题配置
│
├── Services/                    # 服务层
│   ├── MusicPlayerService.swift    # 核心播放服务
│   ├── MusicLibraryService.swift   # 音乐库管理
│   ├── FileImportService.swift     # 文件导入
│   └── LyricParserService.swift    # 歌词解析
│
├── Views/                       # 视图层
│   ├── Player/                 # 播放器界面
│   │   ├── PlayerView.swift
│   │   └── MiniPlayerView.swift
│   ├── Library/                # 音乐库界面
│   │   ├── LibraryView.swift
│   │   └── SongsListView.swift
│   ├── Settings/               # 设置界面
│   │   └── SettingsView.swift
│   └── Profile/                # 个人中心
│       └── ProfileView.swift
│
├── Assets.xcassets/            # 资源文件
├── ContentView.swift           # 主视图容器
├── MusicPlayerApp.swift        # 应用入口
└── Info.plist                 # 应用配置
```

---

## 🔧 技术栈

- **UI 框架**：SwiftUI
- **音频播放**：AVFoundation
- **后台播放**：AVAudioSession + MediaPlayer Framework
- **数据存储**：UserDefaults + Codable
- **文件导入**：UIDocumentPickerViewController
- **歌词解析**：正则表达式解析 LRC 格式

---

## 📖 使用说明

### 导入音乐

1. 打开应用，进入「音乐库」页面
2. 点击右上角 **+** 按钮
3. 选择本地音乐文件（支持多选）
4. 等待导入完成

### 使用歌词

将 `.lrc` 歌词文件与音乐文件放在同一目录，文件名相同：

```
/Music/
  ├── 夜曲.mp3
  └── 夜曲.lrc   ← 自动匹配
```

歌词文件格式示例：
```
[ti:夜曲]
[ar:周杰伦]
[al:十一月的萧邦]
[00:01.23]为你弹奏萧邦的夜曲
[00:05.45]纪念我死去的爱情
```

### 创建歌单

1. 进入「音乐库」→「歌单」标签
2. 点击「创建新歌单」
3. 输入歌单名称
4. 长按歌曲可添加到歌单

---

## 🔄 GitHub Actions 自动构建

本项目已配置 GitHub Actions，推送代码后会自动编译：

1. Fork 本仓库
2. 进入 Actions 页面
3. 等待构建完成
4. 在 Releases 或 Artifacts 下载 IPA

---

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## 🙏 致谢

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Apple 的现代 UI 框架
- [AVFoundation](https://developer.apple.com/av-foundation/) - Apple 的音视频框架

---

## 📞 联系方式

如有问题或建议，欢迎提交 [Issue](../../issues)

---

<p align="center">
  Made with ❤️ for music lovers
</p>
