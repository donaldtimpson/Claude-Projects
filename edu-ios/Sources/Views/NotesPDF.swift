import SwiftUI
import WebKit
import UIKit

// Wraps a generated file URL so it can drive a SwiftUI `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

// Presents the system share sheet (Save to Files, Print, Mail, AirDrop, …).
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// Renders a lecture note (Markdown + KaTeX) to a print-styled PDF using an
// offscreen WKWebView. The in-app note view is dark-themed; the PDF is light
// (dark text on white) so it reads and prints well on paper. Requires a network
// connection (KaTeX/marked load from CDN, same as the in-app note renderer).
@MainActor
final class NotesPDFExporter: NSObject, WKScriptMessageHandler {
    private var continuation: CheckedContinuation<CGFloat, Never>?
    private var webView: WKWebView?
    private let pageWidth: CGFloat = 612 // US Letter width in points

    func export(markdown: String, title: String) async -> URL? {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "rendered")
        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: pageWidth, height: 792), configuration: config)
        webView = web
        web.loadHTMLString(
            Self.printHTML(markdown: markdown, title: title),
            baseURL: URL(string: "https://timpson-lyceum.vercel.app")
        )

        // Wait for the page to report its rendered height (with a safety timeout so
        // a failed CDN load can't hang the export).
        let contentHeight: CGFloat = await withCheckedContinuation { c in
            self.continuation = c
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                self?.resume(with: 1200)
            }
        }

        config.userContentController.removeScriptMessageHandler(forName: "rendered")
        web.frame = CGRect(x: 0, y: 0, width: pageWidth, height: contentHeight)

        let pdfConfig = WKPDFConfiguration()
        pdfConfig.rect = CGRect(x: 0, y: 0, width: pageWidth, height: contentHeight)
        defer { webView = nil }
        guard let data = try? await web.pdf(configuration: pdfConfig) else { return nil }

        let base = title.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
        let name = base.trimmingCharacters(in: .whitespaces).isEmpty ? "Notes" : base
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private func resume(with height: CGFloat) {
        continuation?.resume(returning: height)
        continuation = nil
    }

    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "rendered" else { return }
        var h: CGFloat = 1200
        if let d = message.body as? Double { h = CGFloat(d) }
        else if let i = message.body as? Int { h = CGFloat(i) }
        resume(with: h + 48) // a little bottom breathing room
    }

    private static func printHTML(markdown: String, title: String) -> String {
        let mdPayload = (try? String(data: JSONEncoder().encode(markdown), encoding: .utf8)) ?? "\"\""
        let titlePayload = (try? String(data: JSONEncoder().encode(title), encoding: .utf8)) ?? "\"\""
        return """
        <!doctype html><html><head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css'>
        <script src='https://cdn.jsdelivr.net/npm/marked/marked.min.js'></script>
        <script defer src='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js'></script>
        <script defer src='https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js'></script>
        <style>
          html,body{margin:0;background:#ffffff;color:#1a1512;
            font:16px/1.65 Georgia,'Times New Roman',serif;padding:36px}
          h1.doc-title{font-size:24px;color:#7a1420;font-family:Georgia,serif;
            border-bottom:2px solid #b8860b;padding-bottom:10px;margin:0 0 22px}
          h2{font-size:20px;color:#7a1420;margin-top:26px}
          h3{font-size:17px;color:#7a1420}
          a{color:#7a1420}
          code{background:#f2ede0;color:#6e2020;padding:1px 4px;border-radius:4px}
          pre{background:#f7f3ea;padding:12px;border-radius:8px;overflow-x:auto}
          .katex{color:#1a1512}
          .katex-display{overflow-x:auto;overflow-y:hidden}
        </style></head>
        <body>
        <h1 class='doc-title' id='t'></h1>
        <div id='c'></div>
        <script>
        var md=\(mdPayload), title=\(titlePayload);
        document.getElementById('t').textContent=title;
        try{document.getElementById('c').innerHTML=window.marked?marked.parse(md):md}
        catch(e){document.getElementById('c').textContent=md}
        function done(){
          try{if(window.renderMathInElement)renderMathInElement(document.body,{delimiters:[
            {left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false})}catch(e){}
          window.webkit.messageHandlers.rendered.postMessage(document.body.scrollHeight);
        }
        window.addEventListener('load',function(){setTimeout(done,300)});
        </script></body></html>
        """
    }
}
