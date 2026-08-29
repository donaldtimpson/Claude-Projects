package com.timpsonlyceum.lyceum.ui.components

import android.annotation.SuppressLint
import android.graphics.Color as AndroidColor
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.WebViewAssetLoader
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

/**
 * The site that already embeds these videos on the web.
 *
 * The IFrame API validates the embedder's origin, and it has to be a real
 * external https origin that matches the page's base URL — *not* youtube.com
 * itself, which is self-referential and comes back as error 152. This one value
 * is the difference between a working player and an opaque failure, which is why
 * it is spelled out rather than derived from AppConfig: pointing the app at a
 * dev server must not change the origin the player claims.
 */
private const val EMBED_ORIGIN = "https://timpson-lyceum.vercel.app"

/**
 * A virtual https origin backed by the APK's assets, used for the notes page.
 *
 * The bundled brand fonts have to be same-origin with the page that asks for
 * them: a `file://` URL referenced from an `https` document is blocked, and
 * base64-inlining an 850 KB face into every note is worse. [WebViewAssetLoader]
 * serves `/assets/...` from the APK over this origin instead.
 */
private const val ASSET_ORIGIN = "https://appassets.androidplatform.net"

private val jsonEnc = Json

/** Human-readable explanation of a YouTube IFrame Player API error code. */
fun youtubeErrorMessage(code: Int): String = when (code) {
    2 -> "Video unavailable (bad video ID). [YT error 2]"
    5 -> "Playback error in the HTML5 player. [YT error 5]"
    100 -> "This video was removed or is private. [YT error 100]"
    101, 150 -> "The owner doesn't allow this video to be played in embedded players. Watch it on YouTube. [YT error $code]"
    else -> "Video couldn't be played. [YT error $code]"
}

/**
 * Embedded YouTube player.
 *
 * Uses the IFrame Player API (`new YT.Player(...)`) rather than a bare
 * `<iframe src=…/embed>`, the same choice the iOS app made and for the same
 * reason: the bare embed frequently fails inside a system WebView with an
 * on-screen error that says nothing useful. Needs a network connection.
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun YouTubePlayer(
    videoId: String,
    modifier: Modifier = Modifier,
    onError: (Int) -> Unit = {},
) {
    val currentOnError by rememberUpdatedState(onError)

    AndroidView(
        modifier = modifier,
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                // Without this the player will not start until the user taps
                // twice — once to satisfy the gesture requirement, once to play.
                settings.mediaPlaybackRequiresUserGesture = false
                setBackgroundColor(AndroidColor.BLACK)
                isVerticalScrollBarEnabled = false
                isHorizontalScrollBarEnabled = false
                webViewClient = WebViewClient()
                addJavascriptInterface(object {
                    @JavascriptInterface
                    fun onError(code: Int) { currentOnError(code) }
                }, "AndroidYT")
            }
        },
        update = { web ->
            web.loadDataWithBaseURL(EMBED_ORIGIN, playerHtml(videoId), "text/html", "utf-8", null)
        },
        onRelease = { it.destroy() },
    )
}

private fun playerHtml(videoId: String): String = """
<!doctype html><html><head>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<style>html,body{margin:0;background:#000;height:100%;overflow:hidden}
#player{position:absolute;top:0;left:0;width:100%;height:100%}</style></head>
<body><div id='player'></div>
<script src='https://www.youtube.com/iframe_api'></script>
<script>
function onYouTubeIframeAPIReady(){
  new YT.Player('player',{
    width:'100%',height:'100%',videoId:'$videoId',
    playerVars:{playsinline:1,rel:0,modestbranding:1,origin:'$EMBED_ORIGIN'},
    events:{
      onError:function(e){try{AndroidYT.onError(e.data)}catch(err){}}
    }
  });
}
</script></body></html>
""".trimIndent()

/**
 * Renders a lecture note's Markdown + KaTeX and reports its content height back,
 * so it can size itself inside a scrolling parent instead of scrolling within a
 * scroll.
 *
 * Uses `marked-katex-extension`, which tokenises `${'$'}…${'$'}` as math *before*
 * markdown escaping runs. Plain `marked` CommonMark-escapes ASCII punctuation
 * inside math — turning `\,` into a comma and `\\` line breaks into a single
 * backslash — because it has no idea where the math is. The extension hands
 * KaTeX the raw source, which is what the web app's remark-math pipeline does.
 *
 * The KaTeX version is pinned to the web app's on purpose: when the iOS app
 * trailed at 0.16 the same markdown rendered clean on the site and red in the
 * app, because 0.16 rejects things 0.17 accepts.
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun MathWebView(markdown: String, modifier: Modifier = Modifier) {
    var height by remember(markdown) { mutableIntStateOf(240) }

    AndroidView(
        modifier = modifier.fillMaxWidth().height(height.dp),
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                setBackgroundColor(AndroidColor.TRANSPARENT)
                isVerticalScrollBarEnabled = false
                val loader = WebViewAssetLoader.Builder()
                    .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(context))
                    .build()
                webViewClient = object : WebViewClient() {
                    override fun shouldInterceptRequest(
                        view: WebView,
                        request: WebResourceRequest,
                    ): WebResourceResponse? = loader.shouldInterceptRequest(request.url)
                }
                addJavascriptInterface(object {
                    @JavascriptInterface
                    fun setHeight(px: Int) {
                        post { height = px + 6 }
                    }
                }, "AndroidNote")
            }
        },
        update = { web ->
            web.loadDataWithBaseURL(
                "$ASSET_ORIGIN/assets/note.html", noteHtml(markdown), "text/html", "utf-8", null,
            )
        },
        onRelease = { it.destroy() },
    )
}

private fun noteHtml(markdown: String): String {
    val payload = jsonEnc.encodeToString(String.serializer(), markdown)
    return """
<!doctype html><html><head>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/katex@0.17.0/dist/katex.min.css'>
<script src='https://cdn.jsdelivr.net/npm/marked/marked.min.js'></script>
<script src='https://cdn.jsdelivr.net/npm/katex@0.17.0/dist/katex.min.js'></script>
<script src='https://cdn.jsdelivr.net/npm/marked-katex-extension@5/lib/index.umd.js'></script>
<style>
/* The brand faces, served from assets. iOS gets EB Garamond via the system
   Georgia fallback; Android has neither, so without this the notes render in
   whatever default serif the WebView picks and stop matching the app around
   them. loadDataWithBaseURL keeps an https base URL, so these are absolute
   the page is served from a virtual asset origin so these stay same-origin. */
@font-face{font-family:'EB Garamond';src:url('/assets/fonts/eb_garamond.ttf') format('truetype');font-display:swap}
@font-face{font-family:'Cinzel';src:url('/assets/fonts/cinzel.ttf') format('truetype');font-display:swap}
html,body{margin:0;background:transparent;color:#f5ecd8;
font:17px/1.6 'EB Garamond',Georgia,serif;padding:2px}
h1,h2,h3{color:#cfa135;font-family:'Cinzel','EB Garamond',Georgia,serif}
h2{font-size:20px} h3{font-size:17px}
a{color:#ddb954}
code{background:#2d1212;color:#e8cb7e;padding:1px 4px;border-radius:4px}
pre{background:#2d1212;padding:10px;border-radius:8px;overflow-x:auto}
.katex{color:#f5ecd8}
.katex-display{overflow-x:auto;overflow-y:hidden}</style></head>
<body><div id='c'></div>
<script>
var md=$payload;
try{marked.use(markedKatex({throwOnError:false,nonStandard:true}));document.getElementById('c').innerHTML=marked.parse(md);}
catch(e){document.getElementById('c').textContent=md;}
window.addEventListener('load',function(){setTimeout(function(){
  try{AndroidNote.setHeight(document.body.scrollHeight)}catch(err){}
},250);});
</script>
</body></html>
""".trimIndent()
}
