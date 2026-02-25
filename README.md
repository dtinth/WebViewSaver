# WebViewSaver

A minimal macOS screen saver that displays a web page using WKWebView. A Swift alternative to [WebViewScreenSaver](https://github.com/liquidx/webviewscreensaver) and [WebSaver](https://github.com/tlrobinson/WebSaver).

## Configuration

Create a JSON config file at `~/.config/WebViewSaver/config.json`:

```json
{"url": "https://example.com"}
```

## Building

**Using Xcode:**

1. Open `WebViewSaver.xcodeproj` in Xcode.
2. Build the project (Cmd+B).
3. Open the built `WebViewSaver.saver` from Derived Data to install it.

**Using the command line:**

```bash
xcodebuild -scheme WebViewSaver -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/WebViewSaver-*/Build/Products/Debug/WebViewSaver.saver
```

## Notes

- The screen saver reads the config from your real home directory, not the sandboxed container.
- A loading screen with progress is shown while the page loads, followed by a fade-in.
- Uses a [private WKWebView API](https://github.com/liquidx/webviewscreensaver/commit/8271566) to disable window occlusion detection, which prevents macOS from throttling animations in the screensaver context.

## Acknowledgments

- [Creating a macOS Screensaver in SwiftUI](https://digitalbunker.dev/creating-a-macos-screensaver-in-swiftui/) by Aryaman Sharda
- [liquidx/webviewscreensaver](https://github.com/liquidx/webviewscreensaver) for the occlusion detection fix
