import SwiftUI
import WebKit

// Embedded YouTube player (WKWebView). Uses the YouTube IFrame Player API
// (`new YT.Player(...)`) rather than a bare <iframe src=…/embed> — the same
// approach as Google's official youtube-ios-player-helper. The IFrame API is
// far more reliable inside WKWebView (a bare embed often fails to load the
// player with an opaque on-screen error). Requires a network connection.
struct YouTubePlayer: UIViewRepresentable {
    let videoId: String
    /// Start here (seconds), e.g. a transcript search hit's moment.
    var start: Int? = nil
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
        // Load once per video; SwiftUI calls this on every parent update.
        let key = "\(videoId)@\(start ?? 0)"
        guard context.coordinator.loadedKey != key else { return }
        context.coordinator.loadedKey = key
        // The IFrame API validates the embedder's origin. It must be a real,
        // external https web origin that matches the baseURL below — NOT
        // youtube.com itself (self-referential origins are rejected → error 152).
        // Use the site that already embeds these videos successfully on the web.
        let origin = AppConfig.siteOrigin
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
            playerVars:{playsinline:1,rel:0,modestbranding:1,start:\(start ?? 0),origin:'\(origin)'},
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
        var loadedKey: String?
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
    // Keep this KaTeX version in step with the web app's (package.json). When the
    // app trailed at 0.16.11 the same markdown rendered clean on the site and red
    // in the app: 0.16 rejects a literal `·` inside \text{} and a superscript
    // with no base, both of which 0.17 accepts.

    static let head = """
    <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/katex@0.17.0/dist/katex.min.css'>
    <script src='https://cdn.jsdelivr.net/npm/marked/marked.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/katex@0.17.0/dist/katex.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/marked-katex-extension@5/lib/index.umd.js'></script>
    """

    // Renders the JSON-encoded markdown `payload` into #c with math-aware marked, then posts
    // the content height to the named WKScriptMessageHandler once fonts have settled. `pre`
    // runs before parsing (e.g. the PDF sets its title). `throwOnError:false` keeps a bad
    // equation from blanking the whole note.
    /// Content styling shared by notes, the syllabus, quiz prompts and problem sets:
    /// the app's fonts (Source Serif 4 to read, Inter for subheads) and its light
    /// and dark colors, switching with the app's appearance.
    static let css = """
    :root{--ink:#f5ecd8;--soft:#c9b596;--rule:#4a1a1a;--tint:#2d1212;--accent:#ddb954;--link:#cfa135;--ornament:#cfa135}
    @media (prefers-color-scheme: light){:root{--ink:#1d1814;--soft:#5a4f46;--rule:#ddd2c3;--tint:#f0eae1;--accent:#8a1f1f;--link:#8f2222;--ornament:#b8860b}}
    html,body{margin:0;background:transparent;color:var(--ink);-webkit-text-size-adjust:100%}
    body{font:17px/1.6 'Source Serif 4',Georgia,serif;padding:2px}
    p,li{margin:.55em 0}
    h1{font-size:20px;font-weight:700;margin:1em 0 .4em}
    h2{font:600 13px/1.4 'Inter',-apple-system,sans-serif;letter-spacing:.06em;text-transform:uppercase;color:var(--soft);margin:1.6em 0 .5em}
    h3{font-size:17px;font-weight:600;margin:1.2em 0 .3em}
    h1:first-child,h2:first-child,h3:first-child{margin-top:0}
    strong{font-weight:650}
    a{color:var(--link)}
    code{background:var(--tint);padding:1px 4px;border-radius:4px;font-size:.9em}
    pre{background:var(--tint);padding:10px;border-radius:8px;overflow-x:auto}
    blockquote{margin:.8em 0;padding-left:12px;border-left:3px solid var(--ornament);color:var(--soft)}
    hr{border:0;border-top:1px solid var(--rule);margin:1.2em 0}
    table{border-collapse:collapse;width:100%;margin:14px 0;font-size:15px;display:block;overflow-x:auto}
    th,td{border-bottom:1px solid var(--rule);padding:7px 10px;text-align:left;vertical-align:top}
    th{font:600 13px 'Inter',-apple-system,sans-serif}
    td{color:var(--soft)}
    .katex{font-size:1.06em;color:var(--ink)}
    .katex-display{overflow-x:auto;overflow-y:hidden}
    """

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
        // Reload only when the content changes (colors follow the appearance via CSS).
        guard context.coordinator.loaded != markdown else { return }
        context.coordinator.loaded = markdown
        web.loadHTMLString(Self.html(markdown), baseURL: URL(string: AppConfig.siteOrigin))
    }

    private static func html(_ md: String) -> String {
        let payload = (try? String(data: JSONEncoder().encode(md), encoding: .utf8)) ?? "\"\""
        return """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        \(NoteWeb.head)
        <style>\(NoteWeb.css)</style></head>
        <body><div id='c'></div>
        \(NoteWeb.script(payload: payload, handler: "h", delayMs: 250))
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: MathWebView
        var loaded: String?
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
