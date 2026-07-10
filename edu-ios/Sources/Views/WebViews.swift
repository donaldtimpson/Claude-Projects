import SwiftUI
import WebKit

// Embedded YouTube player (WKWebView + iframe embed — the only supported way to
// play YouTube content). Requires a network connection.
struct YouTubePlayer: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .black
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let html = """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <style>html,body{margin:0;background:#000;height:100%}
        .wrap{position:relative;padding-bottom:56.25%;height:0}
        iframe{position:absolute;top:0;left:0;width:100%;height:100%}</style></head>
        <body><div class='wrap'>
        <iframe src='https://www.youtube.com/embed/\(videoId)?playsinline=1'
          frameborder='0' allow='accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
          allowfullscreen></iframe></div></body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
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
        <style>html,body{margin:0;background:transparent;color:#2b2320;
        font:16px/1.55 -apple-system,Georgia,serif;padding:2px}
        h2{color:#7b1113;font-size:20px} h3{color:#7b1113;font-size:17px}
        code{background:#ece3cf;padding:1px 4px;border-radius:4px}
        pre{background:#ece3cf;padding:10px;border-radius:8px;overflow-x:auto}
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
