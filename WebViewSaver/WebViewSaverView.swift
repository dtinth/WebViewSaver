import ScreenSaver
import SwiftUI
import WebKit

// MARK: - Private API to prevent WKWebView throttling in screensaver

@objc private protocol WKWebViewPrivate {
    @objc optional func _setWindowOcclusionDetectionEnabled(_ enabled: Bool)
}

// MARK: - ScreenSaverView entry point

class WebViewSaverView: ScreenSaverView {
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        wantsLayer = true

        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.width, .height]
        addSubview(hostingController.view)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - Config

private func readConfigURL() -> String? {
    let realHome = getpwuid(getuid()).pointee.pw_dir.flatMap { String(cString: $0) } ?? ""
    let configPath = "\(realHome)/.config/WebViewSaver/config.json"
    guard let data = FileManager.default.contents(atPath: configPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let urlString = json["url"] as? String
    else {
        return nil
    }
    return urlString
}

private func configFilePath() -> String {
    let realHome = getpwuid(getuid()).pointee.pw_dir.flatMap { String(cString: $0) } ?? ""
    return "\(realHome)/.config/WebViewSaver/config.json"
}

// MARK: - SwiftUI Views

private struct ContentView: View {
    var body: some View {
        if let urlString = readConfigURL(), let url = URL(string: urlString) {
            LoadingWebView(url: url, urlString: urlString)
                .ignoresSafeArea()
        } else {
            ZStack {
                Color.black
                Text("No URL configured. Put {\"url\":...} in \(configFilePath())")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .ignoresSafeArea()
        }
    }
}

private struct LoadingWebView: View {
    let url: URL
    let urlString: String
    @State private var isLoaded = false
    @State private var loadProgress: Double = 0

    var body: some View {
        ZStack {
            Color.black

            WebView(url: url, isLoaded: $isLoaded, loadProgress: $loadProgress)
                .opacity(isLoaded ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: isLoaded)

            if !isLoaded {
                Text("Loading \(urlString)... \(Int(loadProgress * 100))%")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
            }
        }
    }
}

private struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var isLoaded: Bool
    @Binding var loadProgress: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)

        // Disable window occlusion detection so animations aren't throttled.
        // Fix from: https://github.com/liquidx/webviewscreensaver/commit/8271566
        if webView.responds(to: Selector(("_setWindowOcclusionDetectionEnabled:"))) {
            (webView as AnyObject)._setWindowOcclusionDetectionEnabled(false)
        }

        webView.navigationDelegate = context.coordinator
        context.coordinator.progressObservation = webView.observe(\.estimatedProgress) { webView, _ in
            DispatchQueue.main.async {
                self.loadProgress = webView.estimatedProgress
            }
        }

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        var progressObservation: NSKeyValueObservation?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            progressObservation = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.parent.isLoaded = true
            }
        }
    }
}
