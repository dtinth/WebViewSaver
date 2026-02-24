import ScreenSaver
import WebKit

class WebViewSaverView: ScreenSaverView {

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        wantsLayer = true

        let realHome = getpwuid(getuid()).pointee.pw_dir.flatMap { String(cString: $0) } ?? ""
        let configPath = "\(realHome)/.config/WebViewSaver/config.json"

        guard let urlString = readConfigURL(configPath: configPath),
              let url = URL(string: urlString) else {
            layer = CALayer()
            layer?.backgroundColor = NSColor.black.cgColor
            let textLayer = CATextLayer()
            textLayer.string = "No URL configured. Put {\"url\":...} in \(configPath)"
            textLayer.fontSize = 24
            textLayer.foregroundColor = NSColor.green.cgColor
            textLayer.alignmentMode = .center
            textLayer.isWrapped = true
            textLayer.frame = CGRect(x: 20, y: bounds.midY - 50, width: bounds.width - 40, height: 100)
            textLayer.contentsScale = 2.0
            layer?.addSublayer(textLayer)
            return
        }

        let webView = WKWebView(frame: bounds)
        webView.autoresizingMask = [.width, .height]
        addSubview(webView)
        webView.load(URLRequest(url: url))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func readConfigURL(configPath: String) -> String? {
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["url"] as? String
        else {
            return nil
        }
        return urlString
    }
}
