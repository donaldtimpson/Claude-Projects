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
        // The IFrame API validates the embedder's origin. It must be a real,
        // external https web origin that matches the baseURL below — NOT
        // youtube.com itself (self-referential origins are rejected → error 152).
        // Use the site that already embeds these videos successfully on the web.
        let origin = "https://timpson-lyceum.vercel.app"
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

// Shared Markdown + KaTeX rendering for lecture notes, used by BOTH the in-app note view
// and the PDF export so they can't drift.
//
// Uses `marked-katex-extension`, which tokenizes `$…$`/`$$…$$` as math BEFORE markdown
// escaping runs. Plain `marked` (what we used before) CommonMark-escapes ASCII punctuation
// inside math — turning `\,` into a literal comma, `\\` line breaks into a single `\`, and
// `\%` into a KaTeX comment — because it doesn't know about math delimiters. The extension
// hands KaTeX the RAW math source instead, mirroring the web app's remark-math pipeline for
// exact parity. Scripts load synchronously in order (marked, then katex, then the extension,
// which reads `window.katex` at load); no auto-render pass is needed.
enum NoteWeb {
    static let head = """
    <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css'>
    <script src='https://cdn.jsdelivr.net/npm/marked/marked.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/marked-katex-extension@5/lib/index.umd.js'></script>
    """

    // Renders the JSON-encoded markdown `payload` into #c with math-aware marked, then posts
    // the content height to the named WKScriptMessageHandler once fonts have settled. `pre`
    // runs before parsing (e.g. the PDF sets its title). `throwOnError:false` keeps a bad
    // equation from blanking the whole note.
    static func script(payload: String, handler: String, delayMs: Int, pre: String = "") -> String {
        """
        <script>
        var md=\(payload);
        \(pre)
        try{marked.use(markedKatex({throwOnError:false,nonStandard:true}));document.getElementById('c').innerHTML=marked.parse(md);}
        catch(e){document.getElementById('c').textContent=md;}
        window.addEventListener('load',function(){setTimeout(function(){window.webkit.messageHandlers.\(handler).postMessage(document.body.scrollHeight);},\(delayMs));});
        </script>
        """
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
        \(NoteWeb.head)
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
        \(NoteWeb.script(payload: payload, handler: "h", delayMs: 250))
        </body></html>
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
