# Elythra Music

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Elythra Music Logo" width="200"/>
</p>

<p align="center">
  <strong>🎵 Your music, your way 🎵</strong>
</p>

<p align="center">
  <a href="https://github.com/btrshaolin/ElythraMusic/releases">
    <img src="https://img.shields.io/github/v/release/btrshaolin/ElythraMusic?style=for-the-badge&logo=github&color=blue" alt="GitHub Release"/>
  </a>
  <a href="https://github.com/btrshaolin/ElythraMusic/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/btrshaolin/ElythraMusic?style=for-the-badge&color=green" alt="License"/>
  </a>
  <a href="https://github.com/btrshaolin/ElythraMusic/stargazers">
    <img src="https://img.shields.io/github/stars/btrshaolin/ElythraMusic?style=for-the-badge&color=yellow" alt="Stars"/>
  </a>
</p>

---

## 🌟 What is Elythra Music?

**Elythra Music** is a cross-platform music streaming app built with Flutter, delivering a premium music experience with enhanced lyrics, authentication, and improved performance.

## 🔧 Recent Fixes (Latest Update)

This version includes comprehensive bug fixes and stability improvements:

### ✅ Critical Issues Resolved
- **Fixed all compilation errors** - App now builds successfully with `flutter analyze` showing 0 errors
- **MediaItem conflicts resolved** - Fixed inheritance issues and import conflicts by implementing ElythraMediaItem
- **Share functionality restored** - Updated share_plus API compatibility (5/5 instances fixed)
- **Null-safety improvements** - Fixed Stream access issues and method signature mismatches
- **Type conversion fixes** - Resolved MediaPlaylist conflicts and LyricsModel compatibility
- **Dependencies updated** - Added missing image package and resolved import issues
- **Branding cleanup** - Removed all leftover "BloomeeTunes" and "Metrolist" references

### 🛠 Build Verification
```bash
flutter pub get    # ✅ Dependencies resolved successfully
flutter analyze    # ✅ 0 errors, only minor warnings/info messages
```

### 📦 Dependency Updates (Latest)
- **Updated 16 core packages** to latest compatible versions
- **Maintained compatibility** with Dart 3.5.4/Flutter 3.24.5
- **Major updates**: bloc, cached_network_image, http, image, rxdart, and more
- **Zero breaking changes** - all functionality preserved
- See [DEPENDENCY_UPDATES.md](DEPENDENCY_UPDATES.md) for detailed changelog

### ✨ Key Highlights
- 🎶 **Stream millions of songs** from multiple sources
- 📱 **Cross-platform** - Android, iOS, Windows, Linux, macOS
- 🎨 **Beautiful UI** with modern design
- 📥 **Download & offline playback**
- 🎵 **Enhanced synchronized lyrics**
- 🔐 **Google Sign-In authentication**
- 🎧 **High-quality audio** up to 320kbps
- 🌐 **No ads, completely free**

---

## 🚀 Features

### 🎵 Core Music Features
- **Multi-platform support**: Android, iOS, Windows, Linux, macOS
- **High-quality streaming**: Up to 320 kbps audio quality
- **Multiple music sources**: YouTube Music, Saavn, Spotify integration
- **Offline downloads**: Cache songs for offline listening
- **Smart playlists**: Create and manage custom playlists
- **Audio effects**: Equalizer and audio enhancement
- **Background playback**: Continue listening while using other apps

### 🎤 Enhanced Lyrics Experience
- **Synchronized lyrics**: Real-time lyrics display with music
- **Plain text lyrics**: Traditional lyrics view
- **Lyrics caching**: Save lyrics for offline viewing
- **Auto-save lyrics**: Automatically save lyrics for future use
- **Multiple lyrics sources**: Fetch from various lyrics providers

### 🔐 Authentication & Sync
- **Google Sign-In**: Secure authentication with Google
- **Cloud sync**: Sync playlists and preferences across devices
- **Backup & restore**: Backup your music library
- **Personalized recommendations**: AI-powered music suggestions

### 🎨 User Experience
- **Modern UI**: Clean, intuitive interface
- **Dark/Light themes**: Multiple theme options
- **Responsive design**: Optimized for all screen sizes
- **Keyboard shortcuts**: Desktop keyboard controls
- **Discord integration**: Rich presence support
- **System integration**: Media keys and notifications

---

## 🏗️ Architecture

The app follows a clean architecture pattern with feature-based organization:

```
lib/
├── core/                    # Core functionality
│   ├── blocs/              # State management (BLoC pattern)
│   ├── model/              # Data models
│   ├── repository/         # Data repositories
│   ├── services/           # Core services
│   ├── theme_data/         # Theme configuration
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── player/            # Music player functionality
│   ├── lyrics/            # Lyrics features
│   └── auth/              # Authentication
└── main.dart              # App entry point
```

---

## 📦 What We Kept From Each Repository

### From BloomeeTunes (Base)
✅ **Core Architecture**
- Flutter + BLoC state management
- Multi-platform support (Android, iOS, Windows, Linux, macOS)
- Isar database for local storage
- Audio service with just_audio

✅ **Music Features**
- YouTube Music integration
- Saavn API integration
- Playlist management
- Download functionality
- Audio caching system
- Discord Rich Presence

✅ **UI Components**
- Responsive design framework
- Custom themes and styling
- Navigation system
- Media controls

### From Metrolist (Adapted to Flutter)
✅ **Authentication System**
- Google Sign-In integration
- Firebase authentication
- User profile management

✅ **Lyrics Engine Concepts**
- Advanced lyrics fetching logic
- Multiple lyrics sources
- Lyrics caching strategies

### From Harmony-Music
✅ **Enhanced Lyrics UI**
- `flutter_lyric` package integration
- Synchronized lyrics display
- Improved lyrics viewer
- Lyrics mode switching (plain/synced)

✅ **UI/UX Improvements**
- Better player controls
- Enhanced visual feedback
- Improved navigation patterns

---

## 🔧 Technical Improvements

### Fixed Issues from BloomeeTunes
- **Audio Service Stability**: Improved audio playback reliability
- **320 kbps Streaming**: Ensured consistent high-quality streaming
- **Error Handling**: Better error management and user feedback
- **Performance**: Optimized caching and memory usage

### New Features Added
- **Enhanced Authentication**: Google Sign-In with Firebase
- **Improved Lyrics**: Synchronized lyrics with flutter_lyric
- **Better Architecture**: Clean feature-based organization
- **Modern UI**: Updated design patterns and components

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅ Full | Primary platform |
| iOS      | ✅ Full | Complete support |
| Windows  | ✅ Full | Desktop optimized |
| Linux    | ✅ Full | Native support |
| macOS    | ✅ Full | Apple ecosystem |
| Web      | 🚧 Limited | Basic functionality |

---

## 🛠️ Installation

### 📱 Mobile (Android/iOS)
1. Download the latest APK from [Releases](https://github.com/btrshaolin/ElythraMusic/releases)
2. Install the APK (enable "Unknown Sources" if needed)
3. Launch and enjoy!

### 💻 Desktop (Windows/Linux/macOS)
1. Download the appropriate installer from [Releases](https://github.com/btrshaolin/ElythraMusic/releases)
2. Run the installer
3. Launch Elythra Music from your applications

### 🔧 Build from Source
```bash
# Clone the repository
git clone https://github.com/btrshaolin/ElythraMusic.git
cd ElythraMusic

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 🔥 Firebase Setup (Google Sign-In)

To enable Google Sign-In functionality, you'll need to configure Firebase:

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/)
2. **Add your Android app** to the project
3. **Download `google-services.json`** and place it in `android/app/`
4. **Configure authentication** in Firebase Console:
   - Go to Authentication > Sign-in method
   - Enable Google sign-in provider
   - Add your app's SHA-1 fingerprint

**Note**: The app includes Firebase scaffolding code but requires your own `google-services.json` file for Google Sign-In to work.

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 Bug Reports
- Use the [issue tracker](https://github.com/btrshaolin/ElythraMusic/issues)
- Include detailed steps to reproduce
- Add screenshots if applicable

### 💡 Feature Requests
- Check existing [issues](https://github.com/btrshaolin/ElythraMusic/issues) first
- Describe the feature and its benefits
- Consider implementation complexity

### 🔧 Code Contributions
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 🙏 Acknowledgments

Special thanks to:
- **BloomeeTunes**: Base architecture and core functionality
- **Metrolist**: Authentication concepts and lyrics engine inspiration
- **Harmony-Music**: UI/UX improvements and enhanced lyrics features
- **Flutter Community**: Amazing packages and support

---

## 📄 License

This project is licensed under the **GPL-3.0 License** - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/btrshaolin/ElythraMusic/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/btrshaolin/ElythraMusic/discussions)

---

<p align="center">
  <strong>Elythra Music - Your music, your way 🎵</strong>
</p>