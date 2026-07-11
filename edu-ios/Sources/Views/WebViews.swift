import SwiftUI
import WebKit

// Embedded YouTube player (WKWebView). Uses the YouTube IFrame Player API
// (`new YT.Player(...)`) rather than a bare <iframe src=…/embed> — the same
// approach as Google's official youtube-ios-player-helper. The IFrame API is
// far more reliable inside WKWebView (a bare embed often fails to load the
// player with an opaque on-screen error). Requires a network connection.
struct YouTubePlayer: UIViewRepresentable {
    let videoId: String
    /// Called with YouTube's numeric IFrame error code (2, 5, 100, 101, 150) if
    /// the player reports one, so the app can surface the real cause.
    var onError: ((Int) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(onError: onError) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "yt")
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .black
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        // Origin must be a real https origin that matches the baseURL below.
        let origin = "https://www.youtube.com"
        let html = """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <style>html,body{margin:0;background:#000;height:100%;overflow:hidden}
        #player{position:absolute;top:0;left:0;width:100%;height:100%}</style></head>
        <body><div id='player'></div>
        <script src='https://www.youtube.com/iframe_api'></script>
        <script>
        function post(m){try{window.webkit.messageHandlers.yt.postMessage(m)}catch(e){}}
        function onYouTubeIframeAPIReady(){
          new YT.Player('player',{
            width:'100%',height:'100%',videoId:'\(videoId)',
            playerVars:{playsinline:1,rel:0,modestbranding:1,origin:'\(origin)'},
            events:{
              onReady:function(){post({t:'ready'})},
              onError:function(e){post({t:'error',code:e.data})}
            }
          });
        }
        </script></body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: origin))
    }

    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        web.configuration.userContentController.removeScriptMessageHandler(forName: "yt")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onError: ((Int) -> Void)?
        init(onError: ((Int) -> Void)?) { self.onError = onError }

        func userContentController(
            _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any] else { return }
            if body["t"] as? String == "error", let code = body["code"] as? Int {
                #if DEBUG
                print("[YouTubePlayer] IFrame error code: \(code) (videoId not embeddable=101/150, not found=100, html5=5, param=2)")
                #endif
                onError?(code)
            }
        }
    }
}

// Renders Markdown + KaTeX math (same $…$ / $$…$$ content as the web app) and
// reports its content height back so it can size itself in a ScrollView.
struct MathWebView: UIViewRepresentable {
    let markdown: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = context.coordinator
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .clear
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        web.loadHTMLString(Self.html(markdown), baseURL: URL(string: "https://timpson-lyceum.vercel.app"))
    }

    private static func html(_ md: String) -> String {
        let payload = (try? String(data: JSONEncoder().encode(md), encoding: .utf8)) ?? "\"\""
        return """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css'>
        <script src='https://cdn.jsdelivr.net/npm/marked/marked.min.js'></script>
        <script defer src='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js'></script>
        <script defer src='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js'></script>
        <style>html,body{margin:0;background:transparent;color:#f5ecd8;
        font:16px/1.6 Georgia,'EB Garamond',serif;padding:2px}
        h1,h2,h3{color:#cfa135;font-family:Georgia,serif}
        h2{font-size:20px} h3{font-size:17px}
        a{color:#ddb954}
        code{background:#2d1212;color:#e8cb7e;padding:1px 4px;border-radius:4px}
        pre{background:#2d1212;padding:10px;border-radius:8px;overflow-x:auto}
        .katex{color:#f5ecd8}
        .katex-display{overflow-x:auto;overflow-y:hidden}</style></head>
        <body><div id='c'></div>
        <script>
        var md=\(payload);
        try{document.getElementById('c').innerHTML=window.marked?marked.parse(md):md}catch(e){document.getElementById('c').textContent=md}
        function done(){try{if(window.renderMathInElement)renderMathInElement(document.body,{delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false})}catch(e){}
        window.webkit.messageHandlers.h.postMessage(document.body.scrollHeight)}
        window.addEventListener('load',function(){setTimeout(done,250)});
        </script></body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: MathWebView
        init(_ parent: MathWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "h")
            webView.configuration.userContentController.add(self, name: "h")
        }

        func userContentController(
            _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
        ) {
            if let h = message.body as? Double {
                parent.height = CGFloat(h) + 6
            } else if let h = message.body as? Int {
                parent.height = CGFloat(h) + 6
            }
        }
    }
}
