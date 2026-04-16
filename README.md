# 🎵 MusicPlayer - iOS Music Player

A modern iOS local music player developed with SwiftUI, supporting local music import and lyrics display.

![Platform](https://img.shields.io/badge/Platform-iOS%2015%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.7-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

### 🎶 Music Playback
- Import local music files (MP3, M4A, FLAC, WAV, AAC)
- Playback controls: play/pause, previous/next, seek
- Playback modes: shuffle, single repeat, list repeat
- Background playback support with lock screen controls

### 📝 Lyrics Display
- Support for .lrc lyrics file parsing
- Real-time synchronized scrolling
- Current line highlighting
- Translated lyrics support

### 🎨 Modern UI
- Dark theme design
- Blur glass effect
- Smooth animation transitions
- Customizable accent colors (6 options)

### 📚 Music Library Management
- Song categorization (All, Albums, Artists, Playlists)
- Create custom playlists
- Favorites feature
- Recently played history
- Search functionality

### ⚙️ Personalization Settings
- Light/dark theme toggle
- Lyrics font size adjustment
- Album cover blur background effect

---

## 📱 Interface Preview

| Player View | Music Library | Settings |
|:---:|:---:|:---:|
| Player interface with controls | Song list view | Theme preferences |

---

## 🚀 Installation

### Option 1: Free Signing Installation (Recommended)

Use your Apple ID for free signing installation. See [Free Installation Guide](FREE_INSTALL_GUIDE.md) for details.

**Quick Steps:**
1. Upload the code to GitHub
2. GitHub Actions automatically compiles and generates IPA
3. Download [Sideloadly](https://sideloadly.io/)
4. Connect your iPhone and sign with Apple ID
5. Trust the developer in Settings

⚠️ **Note**: Free signing requires re-signing every 7 days

### Option 2: Developer Account

If you have an Apple Developer Program account (¥688/year):
1. Open the project in Xcode
2. Configure your Team and Bundle ID
3. Install directly to your device

---

## 🛠️ Development Environment

| Requirement | Version |
|-------------|---------|
| Xcode | 14.0+ |
| Swift | 5.7+ |
| iOS Deployment Target | 15.0+ |
| macOS | 12.0+ (for development) |

---

## 📁 Project Structure

```
MusicPlayer/
├── Models/                      # Data Model Layer
│   ├── Song.swift              # Song model
│   ├── Album.swift             # Album model
│   ├── Artist.swift            # Artist model
│   ├── Playlist.swift          # Playlist model
│   ├── LyricLine.swift         # Lyrics model
│   └── AppTheme.swift          # Theme configuration
│
├── Services/                    # Service Layer
│   ├── MusicPlayerService.swift    # Core playback service
│   ├── MusicLibraryService.swift   # Music library management
│   ├── FileImportService.swift     # File import
│   └── LyricParserService.swift    # Lyrics parsing
│
├── Views/                       # View Layer
│   ├── Player/                 # Player interface
│   │   ├── PlayerView.swift
│   │   └── MiniPlayerView.swift
│   ├── Library/                # Music library interface
│   │   ├── LibraryView.swift
│   │   └── SongsListView.swift
│   ├── Settings/               # Settings interface
│   │   └── SettingsView.swift
│   └── Profile/                # Profile center
│       └── ProfileView.swift
│
├── Assets.xcassets/            # Asset files
├── ContentView.swift           # Main view container
├── MusicPlayerApp.swift        # App entry point
└── Info.plist                  # App configuration
```

---

## 🔧 Tech Stack

- **UI Framework**: SwiftUI
- **Audio Playback**: AVFoundation
- **Background Playback**: AVAudioSession + MediaPlayer Framework
- **Data Storage**: UserDefaults + Codable
- **File Import**: UIDocumentPickerViewController
- **Lyrics Parsing**: Regex-based LRC format parsing

---

## 📖 Usage Guide

### Importing Music

1. Open the app and go to "Music Library"
2. Tap the **+** button in the top right corner
3. Select local music files (multiple selection supported)
4. Wait for import to complete

### Using Lyrics

Place `.lrc` lyrics files in the same directory as music files with matching filenames:

```
/Music/
  ├── Song.mp3
  └── Song.lrc   ← Automatically matched
```

Lyrics file format example:
```
[ti:Song Title]
[ar:Artist Name]
[al:Album Name]
[00:01.23]First lyrics line
[00:05.45]Second lyrics line
```

### Creating Playlists

1. Go to "Music Library" → "Playlists" tab
2. Tap "Create New Playlist"
3. Enter playlist name
4. Long press a song to add it to a playlist

---

## 🔄 GitHub Actions Auto Build

This project is configured with GitHub Actions for automatic compilation on push:

1. Fork this repository
2. Go to the Actions page
3. Wait for the build to complete
4. Download the IPA from Releases or Artifacts

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Submit a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

For questions or suggestions, please submit an [Issue](https://github.com/beallhuang/music_app/issues).

---

<p align="center">
  Made with ❤️ for music lovers
</p>
