import SwiftUI
import WebKit

// Renders a whole problem set — problems with their worked solutions attached —
// inside ONE WKWebView.
//
// The web app gives every problem its own reveal toggle in React. Doing that here
// with one MathWebView per problem would mean 7–10 web views per set, each
// fetching KaTeX and measuring itself. Instead the reveal lives inside the HTML as
// a <details> element per problem, so the whole set costs one web view and one
// KaTeX load, and "reveal all" is a one-line JS call.
//
// Markdown/math rendering reuses NoteWeb so problem sets, lecture notes, and the
// PDF export can't drift apart.
struct ProblemSetWebView: UIViewRepresentable {
    let parts: [ProblemPart]
    let problemsPreamble: String?
    let solutionPreamble: String?
    /// Flipped by the toolbar button; opens or closes every <details> at once.
    let revealAll: Bool
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
        // Only reload when the content itself changes. A reveal-all flip just
        // toggles the existing DOM — reloading would drop every open solution and
        // re-fetch KaTeX.
        let signature = parts.map(\.key).joined(separator: "|")
        if context.coordinator.loadedSignature != signature {
            context.coordinator.loadedSignature = signature
            web.loadHTMLString(html(), baseURL: URL(string: AppConfig.baseURL))
        } else if context.coordinator.lastRevealAll != revealAll {
            web.evaluateJavaScript("setAll(\(revealAll ? "true" : "false"))")
        }
        context.coordinator.lastRevealAll = revealAll
    }

    private func json(_ s: String) -> String {
        (try? String(data: JSONEncoder().encode(s), encoding: .utf8)) ?? "\"\""
    }

    private func html() -> String {
        // Each part becomes: a rendered problem, and (when present) a <details>
        // holding its solution. Markdown is passed as JSON and parsed in-page so
        // quoting/escaping stays identical to the notes renderer.
        let blocks = parts.enumerated().map { idx, part -> String in
            let cls = part.isSection ? "part section" : "part"
            let sol = part.solution.map { s in
                """
                <details class='sol'><summary>Show solution \(part.label)</summary>
                <div class='solbody' data-md='s\(idx)'></div></details>
                """
            } ?? ""
            return "<div class='\(cls)'><div data-md='p\(idx)'></div>\(sol)</div>"
        }.joined()

        var payloads: [String] = []
        for (idx, part) in parts.enumerated() {
            payloads.append("p\(idx):\(json(part.problem))")
            if let s = part.solution { payloads.append("s\(idx):\(json(s))") }
        }
        if let pre = problemsPreamble, !pre.isEmpty { payloads.append("pre:\(json(pre))") }
        if let pre = solutionPreamble, !pre.isEmpty { payloads.append("solpre:\(json(pre))") }

        let preambleDiv = (problemsPreamble?.isEmpty == false)
            ? "<div class='preamble' data-md='pre'></div>" : ""
        let solPreambleDiv = (solutionPreamble?.isEmpty == false)
            ? "<div class='preamble solpre' data-md='solpre'></div>" : ""

        return """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        \(NoteWeb.head)
        <style>
        html,body{margin:0;background:transparent;color:#f5ecd8;
        font:16px/1.6 Georgia,'EB Garamond',serif;padding:2px}
        h1,h2,h3{color:#cfa135;font-family:Georgia,serif}
        h2{font-size:20px} h3{font-size:17px}
        a{color:#ddb954}
        code{background:#2d1212;color:#e8cb7e;padding:1px 4px;border-radius:4px}
        pre{background:#2d1212;padding:10px;border-radius:8px;overflow-x:auto}
        .katex{color:#f5ecd8}
        .katex-display{overflow-x:auto;overflow-y:hidden}
        .preamble{margin-bottom:14px}
        .solpre{border:1px solid rgba(207,161,53,.3);background:rgba(15,4,4,.5);
          border-radius:10px;padding:2px 14px;margin-bottom:14px}
        .part{border:1px solid #4a1a1a;background:rgba(25,8,8,.5);
          border-radius:12px;padding:2px 16px 14px;margin:0 0 18px}
        /* Extra Credit is its own block of work, not another item in the run. */
        .part.section{border-color:rgba(207,161,53,.4);background:rgba(15,4,4,.6);margin-top:28px}
        details.sol{margin-top:6px}
        details.sol summary{cursor:pointer;list-style:none;display:inline-block;
          font:600 11px/1 -apple-system,Georgia,serif;letter-spacing:.15em;text-transform:uppercase;
          color:#c4af8e;border:1px solid #4a1a1a;border-radius:9px;padding:9px 12px}
        details.sol summary::-webkit-details-marker{display:none}
        details[open].sol summary{color:#ddb954;border-color:#b8860b}
        .solbody{border:1px solid rgba(207,161,53,.3);background:rgba(15,4,4,.5);
          border-radius:10px;padding:2px 14px;margin-top:10px}
        </style></head>
        <body><div id='c'>\(preambleDiv)\(solPreambleDiv)\(blocks)</div>
        <script>
        var MD={\(payloads.joined(separator: ","))};
        try{
          marked.use(markedKatex({throwOnError:false,nonStandard:true}));
          document.querySelectorAll('[data-md]').forEach(function(el){
            var k=el.getAttribute('data-md');
            if(MD[k]!==undefined) el.innerHTML=marked.parse(MD[k]);
          });
        }catch(e){}
        function post(){window.webkit.messageHandlers.psh.postMessage(document.body.scrollHeight);}
        function setAll(open){
          document.querySelectorAll('details.sol').forEach(function(d){d.open=open;});
          setTimeout(post,60);
        }
        // A solution opening or closing changes the page height — re-measure so
        // SwiftUI's frame keeps up instead of clipping the revealed answer.
        document.addEventListener('toggle',function(){setTimeout(post,60);},true);
        window.addEventListener('load',function(){setTimeout(post,250);});
        </script>
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: ProblemSetWebView
        var loadedSignature: String?
        var lastRevealAll = false
        init(_ parent: ProblemSetWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "psh")
            webView.configuration.userContentController.add(self, name: "psh")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Re-apply reveal-all if it was on before this load finished.
            if lastRevealAll { webView.evaluateJavaScript("setAll(true)") }
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
