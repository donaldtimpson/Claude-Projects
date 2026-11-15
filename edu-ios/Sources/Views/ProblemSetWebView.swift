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
                <details class='sol'><summary><span class='show'>Show</span><span class='hide'>Hide</span> solution \(part.label)</summary>
                <div class='solbody'><div class='eyebrow'>Solution</div><div data-md='s\(idx)'></div></div></details>
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

        let preambleDiv = (problemsPreamble?.isEmpty == false)
            ? "<div class='preamble' data-md='pre'></div>" : ""

        return """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        \(NoteWeb.head)
        <style>
        \(NoteWeb.css)
        :root{--card:#1a0909;--sol:#cfa135}
        body{padding:1px 0}
        @media (prefers-color-scheme: light){:root{--card:#ffffff}}
        .preamble{margin-bottom:14px;color:var(--soft)}
        /* Each problem is a card, as on the web; solutions sit on a gold rule. */
        .part{border:1px solid var(--rule);background:var(--card);border-radius:12px;
          padding:2px 16px 14px;margin:0 0 16px}
        @media (prefers-color-scheme: light){.part{box-shadow:0 1px 2px rgba(60,40,20,.05),0 2px 8px rgba(60,40,20,.04)}}
        /* Extra Credit is its own block of work, not another item in the run. */
        .part.section{border-color:var(--ornament);margin-top:26px}
        details.sol{margin-top:4px}
        details.sol summary{cursor:pointer;list-style:none;display:inline-block;
          font:600 15px/1.2 'Inter',-apple-system,sans-serif;color:var(--link);padding:6px 0}
        details.sol summary::before{content:'▸';display:inline-block;width:1.1em}
        details[open].sol summary::before{content:'▾'}
        details.sol summary::-webkit-details-marker{display:none}
        details.sol .hide{display:none} details[open].sol .show{display:none} details[open].sol .hide{display:inline}
        .solbody{border-left:3px solid var(--ornament);padding:2px 0 2px 14px;margin-top:8px}
        .eyebrow{font:600 12px/1.4 'Inter',-apple-system,sans-serif;letter-spacing:.07em;text-transform:uppercase;color:var(--soft);margin-top:6px}
        </style></head>
        <body><div id='c'>\(preambleDiv)\(blocks)</div>
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
