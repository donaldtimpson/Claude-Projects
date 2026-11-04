#!/usr/bin/env python3
"""Lesson JSON -> standalone HTML slideshow (for quick visual review as an Artifact).

Mirrors the look of generate_deck.py so the HTML preview matches the .pptx.

Usage:
    python preview.py the-verb            # writes build/the-verb.html
"""
import base64
import html
import json
import math
import re
import sys
from pathlib import Path

from themes import THEMES, get_theme
from lesson_order import numbered_stem

REPO_ROOT = Path(__file__).resolve().parents[3]


def font_stack(name):
    if name == "Georgia":
        return "Georgia, 'Times New Roman', serif"
    return f"'{name}', Georgia, serif"


def font_faces(theme):
    """Inline the theme's .ttf files as @font-face data URIs (CSP blocks CDNs)."""
    out = []
    for family, relpath in (theme.get("fonts") or {}).items():
        data = (REPO_ROOT / relpath).read_bytes()
        b64 = base64.b64encode(data).decode()
        out.append(
            f"@font-face{{font-family:'{family}';font-weight:400 700;font-display:swap;"
            f"src:url(data:font/ttf;base64,{b64}) format('truetype');}}")
    return "".join(out)


def root_vars(theme):
    return (":root{"
            f"--paper:#{theme['paper']}; --ink:#{theme['ink']}; --accent:#{theme['accent']};"
            f"--muted:#{theme['muted']}; --rule:#{theme['rule']}; --answer:#{theme['answer']};"
            f"--diagram:#{theme['diagram']}; --body-bg:#{theme['body_bg']};"
            f"--head-font:{font_stack(theme.get('head_font', 'Georgia'))};"
            f"--body-font:{font_stack(theme.get('body_font', 'Georgia'))};}}")


CSS_BODY = """
* { box-sizing: border-box; }
body { margin:0; background:var(--body-bg); font-family: var(--body-font);
       color:var(--ink); padding:24px; }
.deck { max-width: 960px; margin: 0 auto; }
.slide {
  position: relative; background: var(--paper); aspect-ratio: 16/9;
  border: 1px solid var(--rule); border-radius: 4px; margin-bottom: 22px;
  padding: 52px 64px; box-shadow: 0 2px 10px rgba(0,0,0,.08); overflow: hidden;
}
.slide .foot { position:absolute; left:64px; bottom:22px; font-size:12px;
               font-style:italic; color:var(--muted); }
/* thick-then-thin letterpress rule */
.dbl { border:0; height:0; margin: 0 0 26px;
       border-top: 3px solid var(--accent); box-shadow: 0 4px 0 -3px var(--rule); }
.h { color: var(--accent); font-family: var(--head-font); font-weight: 700; font-size: 34px; margin: 0 0 10px; }
.title-slide { display:flex; flex-direction:column; align-items:center;
               justify-content:center; text-align:center; }
.title-slide .eyebrow { color: var(--muted); font-family: var(--head-font); font-weight:700;
       font-size: 15px; letter-spacing: .28em; text-transform: uppercase; margin: 0 0 8px; }
.title-slide .t { color: var(--accent); font-family: var(--head-font); font-weight:700;
       font-size: 60px; margin: 8px 0; }
.title-slide .st { color: var(--muted); font-style: italic; font-size: 22px; margin-top: 16px; }
.title-slide .dbl { width: 320px; margin: 10px 0; }
.title-slide .motto { color: var(--accent); font-style: italic; font-size: 19px;
       letter-spacing: .03em; margin-top: 16px; }
.defn { font-style: italic; font-size: 30px; line-height: 1.35; margin: 8px 0 26px; }
.exlabel { color: var(--accent); font-weight:700; font-size: 15px; margin: 0 0 8px;
           letter-spacing: .18em; text-transform: uppercase; }
ul.b { list-style: none; padding: 0; margin: 0; }
ul.b li { font-size: 24px; line-height: 1.4; margin-bottom: 12px; padding-left: 26px;
          position: relative; }
ul.b li:before { content: "•"; color: var(--accent); font-weight: 700;
                 position: absolute; left: 0; }
.ex li { font-size: 22px; margin-bottom: 8px; }
.instr { color: var(--muted); font-style: italic; font-size: 18px; margin: 0 0 20px; }
.ansline { color: var(--answer); font-weight: 700; font-size: 20px; margin-top: 3px; padding-left: 22px; }
.qans { color: var(--answer); font-weight: 700; font-size: 20px; margin-left: 4px; }
.ansinline { color: var(--answer); font-weight: 700; margin-left: 6px; }
.anskey { position: absolute; top: 54px; right: 64px; color: var(--accent);
          font-weight: 700; font-size: 14px; letter-spacing: .18em;
          text-transform: uppercase; }
.diagrows { }
strong.hl { color: var(--accent); }
.diagrows li { margin-bottom: 16px; display: flex; align-items: center; gap: 14px; }
svg.diag { display: block; }
svg.diag text { font-family: var(--body-font); font-size: 18px; fill: var(--diagram); }
svg.diag line { stroke: var(--diagram); stroke-width: 1.6; }
svg.diag text.prep { font-size: 16px; }
.cols { display: grid; grid-template-columns: 1fr 1fr; gap: 12px 28px; }
ol.q { padding-left: 0; list-style: none; counter-reset: q; }
ol.q li { counter-increment: q; font-size: 24px; line-height: 1.4; margin-bottom: 14px;
          padding-left: 34px; position: relative; }
ol.q li:before { content: counter(q) "."; color: var(--accent); font-weight: 700;
                 position: absolute; left: 0; }
ol.q.tight li { font-size: 22px; line-height: 1.2; margin-bottom: 5px; }
.ctable { width:100%; border-collapse:collapse; margin-top:6px; }
.ctable td { border-bottom:1px solid var(--rule); padding:16px 0; vertical-align:top; }
.ctable tr:last-child td { border-bottom:0; }
.ctable.dense td { padding:6px 0; }
.ctable td.tlabel { width:24%; color:var(--accent); font-family:var(--head-font);
                    font-weight:700; font-size:28px; padding-right:20px; }
.ctable td.tdesc { font-size:22px; line-height:1.35; }
.ctable .tex { color:var(--muted); font-style:italic; font-size:17px; margin-top:5px; }
.arows { display:flex; flex-direction:column; gap:26px; margin-top:10px; }
.arow { display:flex; align-items:center; gap:32px; }
.adiag { flex:0 0 auto; min-width:390px; }
.anote { font-size:19px; line-height:1.4; }
.anote .asent { color:var(--accent); font-weight:700; margin-bottom:5px; }
"""


_BRAND = {"eyebrow": "", "motto": ""}


def esc(s):
    return html.escape(str(s))


_STRONG = re.compile(r"\*\*([^*]+)\*\*")
_EMPH = re.compile(r"\*([^*]+)\*")


def fmt(s):
    """Escape, then render **word** spans as accent bold (the word an example is
    showing) and *word* spans as <em> — the house use-mention rule (a word
    referred to as a word is wrapped in *asterisks* in the lesson JSON)."""
    s = _STRONG.sub(r'<strong class="hl">\1</strong>', esc(s))
    return _EMPH.sub(r"<em>\1</em>", s)


def _mlist(m):
    """Normalize a modifier field (None | str | list) to a list of words."""
    if not m:
        return []
    return [m] if isinstance(m, str) else list(m)


def _mods_svg(cx, base, words, ch, pad):
    """Slanted adjective-element modifiers beneath a word centered at cx; several
    step to the right. Returns (svg fragments, rightmost x reached)."""
    dx, dy, gap, spread = 15, 20, 6, 9
    n = len(words)
    out, wx, prev, rightmost = [], cx + dx, 0, cx
    for i, word in enumerate(words):
        wd = len(word) * ch + 2 * pad
        if i:
            wx += prev / 2 + wd / 2 + gap
        anchor = cx + (i - (n - 1) / 2) * spread   # slant tops fan under the noun
        out += [f'<line x1="{anchor:.0f}" y1="{base}" x2="{wx:.0f}" y2="{base + dy}"/>',
                f'<text x="{wx:.0f}" y="{base + dy + 17:.0f}" text-anchor="middle">{esc(word)}</text>']
        rightmost = max(rightmost, wx + wd / 2)
        prev = wd
    return out, rightmost


def _appo(a):
    """Normalize an appositive field (None | str | {"word", "mod"}) to a dict."""
    if not a:
        return None
    if isinstance(a, str):
        return {"word": a, "mod": []}
    return {"word": a["word"], "mod": _mlist(a.get("mod"))}


_CH, _PAD = 9.8, 15


def _w(t):
    return len(t) * _CH + 2 * _PAD



# Phrase modifiers ({"prep", "obj", "mod", "o", "omod"}) — mirrors generate_deck.py:
# preposition on a slant, object on a short line beneath; an infinitive keeps
# "to" with its verb in `obj` and omits `prep`.
_PH_DX, _PH_DY, _MOD_DX, _MOD_GAP, _MOD_LEAD = 26, 38, 15, 10, 7


def _is_phrase(m):
    return isinstance(m, dict)


def _mods_right(cx, words):
    wx, prev, right = cx + _MOD_DX, 0, cx
    for i, word in enumerate(words):
        wd = _w(word)
        if i:
            wx += prev / 2 + wd / 2 + 6
        right = max(right, wx + wd / 2)
        prev = wd
    return right


def _mod_plan(items):
    """Left-to-right layout of a slot's modifiers when any is a phrase.
    Returns ([(item, anchor offset)], span)."""
    plan, a = [], _MOD_LEAD
    for m in items:
        plan.append((m, a))
        if _is_comp(m):
            end = _cmod_geom(a, m)[1]
        elif _is_phrase(m):
            hx, wobj = a + _PH_DX, _w(m["obj"])
            end = hx + wobj + (_w(m["o"]) if m.get("o") else 0)
            end = max(end, _mods_right(hx + wobj / 2, _mlist(m.get("mod"))))
            if m.get("o"):
                end = max(end, _mods_right(hx + wobj + _w(m["o"]) / 2, _mlist(m.get("omod"))))
        else:
            wd = _w(m)
            end = a + max(_MOD_DX, wd / 2) + wd / 2
        a = end + _MOD_GAP
    return plan, a


# Compound elements ({"parts", "conj"}) — mirrors generate_deck.py: a fork on the
# baseline for a subject, predicate, or object; one slant per part, the ends
# joined by a dashed line, for a modifier. The conjunction sits between the
# last two parts.
_FG, _FDX, _FSTUB = 56, 20, 10


def _is_comp(x):
    return isinstance(x, dict) and "parts" in x


def _ww(word):
    if _is_comp(word):
        return 2 * (_FSTUB + _FDX) + max(_w(p) for p in word["parts"])
    return _w(word)


def _reach(word):
    return (len(word["parts"]) - 1) / 2 * _FG if _is_comp(word) else 0


def _slot_word_svg(left, width, base, word):
    """(lines, texts) for a slot's word, or its fork when compound."""
    if not _is_comp(word):
        return [], [f'<text x="{left + width/2:.0f}" y="{base - 7}" text-anchor="middle">{esc(word)}</text>']
    parts = word["parts"]
    n = len(parts)
    ys = [base + (i - (n - 1) / 2) * _FG for i in range(n)]
    l1, r2 = left + _FSTUB, left + width - _FSTUB
    l2, r1 = l1 + _FDX, r2 - _FDX
    lines, texts = [], []
    for part, y in zip(parts, ys):
        lines += [f'<line x1="{l1:.0f}" y1="{base}" x2="{l2:.0f}" y2="{y:.0f}"/>',
                  f'<line x1="{l2:.0f}" y1="{y:.0f}" x2="{r1:.0f}" y2="{y:.0f}"/>',
                  f'<line x1="{r1:.0f}" y1="{y:.0f}" x2="{r2:.0f}" y2="{base}"/>']
        texts.append(f'<text x="{(l2 + r1)/2:.0f}" y="{y - 7:.0f}" text-anchor="middle">{esc(part)}</text>')
    xd = l2 + 5
    lines.append(f'<line x1="{xd:.0f}" y1="{ys[0]:.0f}" x2="{xd:.0f}" y2="{ys[-1]:.0f}" stroke-dasharray="5 4"/>')
    texts.append(f'<text x="{xd + 5:.0f}" y="{ys[-2] + 24:.0f}" text-anchor="start">{esc(word.get("conj", "and"))}</text>')
    return lines, texts


def _baseline_svg(base, left, xend, slots):
    """Baseline from left to xend, open across the inside of each fork."""
    out, x = [], left
    for sl, sw, word in sorted(slots, key=lambda t: t[0]):
        if _is_comp(word):
            out.append(f'<line x1="{x:.0f}" y1="{base}" x2="{sl + _FSTUB:.0f}" y2="{base}"/>')
            x = sl + sw - _FSTUB
    out.append(f'<line x1="{x:.0f}" y1="{base}" x2="{xend:.0f}" y2="{base}"/>')
    return out


def _cmod_geom(a, m):
    parts = m["parts"]
    wcj = _w(m.get("conj", "and"))
    out, edge = [], None
    for i, p in enumerate(parts):
        wd = _w(p)
        c = a + max(_MOD_DX, wd / 2) if edge is None else edge + wd / 2
        out.append((c - max(_MOD_DX, wd / 2), c, wd))
        gap = wcj - _PAD if i == len(parts) - 2 else 6
        edge = c + wd / 2 + gap
    return out, out[-1][1] + out[-1][2] / 2


def _cmod_svg(a, base, m):
    geom, right = _cmod_geom(a, m)
    out = []
    for part, (x, c, wd) in zip(m["parts"], geom):
        out += [f'<line x1="{x:.0f}" y1="{base}" x2="{c:.0f}" y2="{base + 20}"/>',
                f'<text x="{c:.0f}" y="{base + 37}" text-anchor="middle">{esc(part)}</text>']
    for (_, c1, _), (_, c2, _) in zip(geom, geom[1:]):
        out.append(f'<line x1="{c1:.0f}" y1="{base + 20}" x2="{c2:.0f}" y2="{base + 20}" stroke-dasharray="5 4"/>')
    (_, c1, w1), (_, c2, w2) = geom[-2], geom[-1]
    mid = ((c1 + w1 / 2) + (c2 - w2 / 2)) / 2
    out.append(f'<text x="{mid:.0f}" y="{base + 37}" text-anchor="middle">{esc(m.get("conj", "and"))}</text>')
    return out, right


def _wslot(word, mods):
    ms = _mlist(mods)
    w = _ww(word)
    if any(isinstance(m, dict) for m in ms):
        w = max(w, _mod_plan(ms)[1])
    return w


def _slot_mods_svg(left, width, base, mods):
    """A slot's modifiers: centered under the word when all are single words,
    laid out left to right when a phrase is among them.
    Returns (fragments, rightmost x, lowest y)."""
    ms = _mlist(mods)
    if not ms:
        return [], left, base
    if not any(isinstance(m, dict) for m in ms):
        frag, r = _mods_svg(left + width / 2, base, ms, _CH, _PAD)
        return frag, r, base + 34   # keeps word-only diagrams at their old height
    out, right, low = [], left, base
    for m, off in _mod_plan(ms)[0]:
        a = left + off
        if _is_comp(m):
            frag, r = _cmod_svg(a, base, m)
            out += frag
            right, low = max(right, r), max(low, base + 37)
            continue
        if not _is_phrase(m):
            wd = _w(m)
            c = a + max(_MOD_DX, wd / 2)
            out += [f'<line x1="{a:.0f}" y1="{base}" x2="{c:.0f}" y2="{base + 20}"/>',
                    f'<text x="{c:.0f}" y="{base + 37}" text-anchor="middle">{esc(m)}</text>']
            right, low = max(right, c + wd / 2), max(low, base + 37)
            continue
        hx, hy = a + _PH_DX, base + _PH_DY
        wobj = _w(m["obj"])
        wo = _w(m["o"]) if m.get("o") else 0
        out += [f'<line x1="{a:.0f}" y1="{base}" x2="{hx:.0f}" y2="{hy}"/>',
                f'<line x1="{hx:.0f}" y1="{hy}" x2="{hx + wobj + wo:.0f}" y2="{hy}"/>',
                f'<text x="{hx + wobj/2:.0f}" y="{hy - 7}" text-anchor="middle">{esc(m["obj"])}</text>']
        right, low = max(right, hx + wobj + wo), max(low, hy + 4)
        if m.get("o"):
            out += [f'<line x1="{hx + wobj:.0f}" y1="{hy - 22}" x2="{hx + wobj:.0f}" y2="{hy}"/>',
                    f'<text x="{hx + wobj + wo/2:.0f}" y="{hy - 7}" text-anchor="middle">{esc(m["o"])}</text>']
            if m.get("omod"):
                frag, r = _mods_svg(hx + wobj + wo / 2, hy, _mlist(m["omod"]), _CH, _PAD)
                out += frag
                right, low = max(right, r), max(low, hy + 37)
        if m.get("mod"):
            frag, r = _mods_svg(hx + wobj / 2, hy, _mlist(m["mod"]), _CH, _PAD)
            out += frag
            right, low = max(right, r), max(low, hy + 37)
        if m.get("prep"):
            # The preposition written along its slant, just above-right of the line.
            ang = math.atan2(_PH_DY, _PH_DX)
            mx = (a + hx) / 2 + math.sin(ang) * 4
            my = (base + hy) / 2 - math.cos(ang) * 4
            out.append(f'<text class="prep" x="{mx:.1f}" y="{my:.1f}" text-anchor="middle" '
                       f'transform="rotate({math.degrees(ang):.1f} {mx:.1f} {my:.1f})">'
                       f'{esc(m["prep"])}</text>')
    return out, right, low

def _overhang(ws, smod, pmod):
    """Room after the subject when its word modifiers step right past it and
    the predicate's modifiers are laid out from the predicate's left edge."""
    sm, pm = _mlist(smod), _mlist(pmod)
    if not sm or any(isinstance(m, dict) for m in sm) or not any(isinstance(m, dict) for m in pm):
        return 0
    return max(0, _mods_right(ws / 2, sm) + _MOD_GAP - ws)


def _diag_parts(x0, base, s, p, o=None, c=None, smod=None, pmod=None, omod=None,
                sappo=None):
    """One baseline's SVG fragments, drawn from x0 at baseline y `base`.
    Returns (lines, texts, mods, right edge, {slot: (left, width)}, depth of the
    modifiers below the baseline — 0 when there are none)."""
    topln, below, texty = base - 24, 13, base - 7
    ap = _appo(sappo)
    ws = _wslot(s, smod)
    appo_text = f"({ap['word']})" if ap else ""
    wappo = _w(appo_text) if ap else 0
    sreg = ws + (wappo if ap else _overhang(ws, smod, pmod))   # subject word + any appositive

    lines, texts, mods = [], [], []
    right = x0
    low = base
    slots = {"s": (x0, ws)}

    def add_mods(left, width, words):
        nonlocal right, low
        frag, rmost, lo = _slot_mods_svg(left, width, base, words)
        mods.extend(frag)
        right, low = max(right, rmost), max(low, lo)

    l, tx = _slot_word_svg(x0, ws, base, s)
    lines += l
    texts += tx
    add_mods(x0, ws, smod)
    if ap:
        texts.append(f'<text x="{x0 + ws + wappo/2:.0f}" y="{texty}" text-anchor="middle">{esc(appo_text)}</text>')
        add_mods(x0 + ws, wappo, ap["mod"])

    if c:
        # Harvey: "Iron | is : heavy" — the copula is set off, not folded into the predicate.
        wc, wp = _w(c), _wslot(p, pmod)
        total = sreg + wc + wp
        x1, x2 = x0 + sreg, x0 + sreg + wc
        lines += _baseline_svg(base, x0, x0 + total, [(x0, ws, s), (x2, wp, p)])
        lines += [f'<line x1="{x1:.0f}" y1="{topln}" x2="{x1:.0f}" y2="{base + below}"/>',
                  f'<line x1="{x2:.0f}" y1="{topln}" x2="{x2:.0f}" y2="{base}"/>']
        texts.append(f'<text x="{x1 + wc/2:.0f}" y="{texty}" text-anchor="middle">{esc(c)}</text>')
        l, tx = _slot_word_svg(x2, wp, base, p)
        lines += l
        texts += tx
        add_mods(x2, wp, pmod)
        slots.update(c=(x1, wc), p=(x2, wp))
    else:
        wp = _wslot(p, pmod)
        wo = _wslot(o, omod) if o else 0
        total = sreg + wp + wo
        x1, x2 = x0 + sreg, x0 + sreg + wp
        lines += _baseline_svg(base, x0, x0 + total,
                               [(x0, ws, s), (x1, wp, p)] + ([(x2, wo, o)] if o else []))
        lines.append(f'<line x1="{x1:.0f}" y1="{topln}" x2="{x1:.0f}" y2="{base + below}"/>')
        l, tx = _slot_word_svg(x1, wp, base, p)
        lines += l
        texts += tx
        add_mods(x1, wp, pmod)
        slots["p"] = (x1, wp)
        if o:
            lines.append(f'<line x1="{x2:.0f}" y1="{topln}" x2="{x2:.0f}" y2="{base}"/>')
            l, tx = _slot_word_svg(x2, wo, base, o)
            lines += l
            texts += tx
            add_mods(x2, wo, omod)
            slots["o"] = (x2, wo)

    right = max(right, x0 + total)
    return lines, texts, mods, right, slots, (low - base if mods else 0)


def diagram_svg(s, p, o=None, c=None, smod=None, pmod=None, omod=None, sappo=None,
                sclause=None, pclause=None, oclause=None):
    """Reed-Kellogg baseline: subject | predicate | object, or Harvey's copular
    form subject | copula : predicate when `c` is given. `smod`/`pmod`/`omod`
    hang adjective-element modifiers (articles, adjectives, possessives,
    demonstratives) on slants beneath the subject, predicate-noun, or object —
    each a word or a list. `sappo` sets an appositive, drawn in parentheses on
    the baseline beside the subject (modern Reed-Kellogg), with its own modifier
    on a slant. `sclause`/`pclause`/`oclause` hang a relative clause on its own
    baseline beneath that slot, a dashed line running from the relative pronoun
    (the clause slot named by "rel") up to its antecedent. An adverbial clause
    names the slot it modifies as "rel" and may set `link`, the connective
    written beside the dashed line."""
    reach = max(_reach(w) for w in (s, p, o))
    base = 30 + reach
    drop, inset = 80, 10          # clause baseline below the main one; connector inset
    clauses = {"s": sclause, "p": pclause, "o": oclause}

    def rel_cx(cl):
        *_, cslots, _ = _diag_parts(0, 0, cl["s"], cl.get("p", ""), cl.get("o"), cl.get("c"),
                                    cl.get("smod"), cl.get("pmod"), cl.get("omod"))
        rl, rw = cslots[cl.get("rel", "s")]
        return rl + rw / 2

    # Shift the main line right so each clause's relative sits straight beneath
    # its antecedent's left end (the clause may reach left of the main line).
    *_, slots0, _ = _diag_parts(0, base, s, p, o, c, smod, pmod, omod, sappo)
    shift = max([0] + [rel_cx(cl) - (slots0[k][0] + inset)
                       for k, cl in clauses.items() if cl and k in slots0])
    lines, texts, mods, right, slots, has_mods = _diag_parts(
        shift, base, s, p, o, c, smod, pmod, omod, sappo)
    bottom = max(70, base + has_mods + 6) if has_mods else 46
    if reach:
        bottom = max(bottom, base + reach + 10)
    for key, cl in clauses.items():
        if not cl or key not in slots:
            continue
        anchor = slots[key][0] + inset
        cl_left = anchor - rel_cx(cl)
        cbase = base + drop
        l2, t2, m2, r2, _, hm2 = _diag_parts(
            cl_left, cbase, cl["s"], cl.get("p", ""), cl.get("o"), cl.get("c"),
            cl.get("smod"), cl.get("pmod"), cl.get("omod"))
        lines += l2 + [f'<line x1="{anchor:.0f}" y1="{base}" x2="{anchor:.0f}" '
                       f'y2="{cbase - 22}" stroke-dasharray="5 4"/>']
        texts += t2
        if cl.get("link"):
            # A connective (e.g. the *when* of an adverbial clause) written on the connector.
            texts.append(f'<text x="{anchor + 6:.0f}" y="{base + (drop - 22) / 2 + 8:.0f}" '
                         f'text-anchor="start">{esc(cl["link"])}</text>')
            r2 = max(r2, anchor + 6 + _w(cl["link"]))
        mods += m2
        right = max(right, r2)
        bottom = max(bottom, cbase + (max(40, hm2 + 6) if hm2 else 16))
    minx = -6 if (mods or bottom > 70) else 0
    width = right + (6 if minx else 0) - minx
    return "".join([
        f'<svg class="diag" width="{width:.0f}" height="{bottom}" '
        f'viewBox="{minx:.0f} 0 {width:.0f} {bottom}" xmlns="http://www.w3.org/2000/svg">',
        *lines, *mods, *texts, '</svg>'])


def render(slide, source, show_answers=False):
    t = slide["type"]
    foot = f'<div class="foot">{esc(source)}</div>'
    if t == "title":
        st = f'<div class="st">{esc(slide["subtitle"])}</div>' if slide.get("subtitle") else ""
        motto = f'<div class="motto">{esc(_BRAND["motto"])}</div>' if _BRAND.get("motto") else ""
        return (f'<section class="slide title-slide">'
                f'<div class="eyebrow">{esc(_BRAND["eyebrow"])}</div>'
                f'<hr class="dbl">'
                f'<h1 class="t">{esc(slide["title"])}</h1>{st}'
                f'<hr class="dbl">{motto}{foot}</section>')
    if t == "definition":
        exs = ""
        if slide.get("examples"):
            lis = "".join(f"<li>{fmt(e)}</li>" for e in slide["examples"])
            exs = f'<p class="exlabel">Examples</p><ul class="b ex">{lis}</ul>'
        return (f'<section class="slide"><h2 class="h">{esc(slide["term"])}</h2><hr class="dbl">'
                f'<div class="defn">{fmt(slide["text"])}</div>{exs}{foot}</section>')
    if t == "concept":
        lis = "".join(f"<li>{fmt(b)}</li>" for b in slide["bullets"])
        return (f'<section class="slide"><h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'<ul class="b">{lis}</ul>{foot}</section>')
    if t == "practice":
        items = slide["items"]
        answers = slide.get("answers") or []
        is_diagram = bool(answers) and isinstance(answers[0], dict)
        tag = '<div class="anskey">Answer Key</div>' if show_answers else ''
        head = (f'<h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'<p class="instr">{fmt(slide["instruction"])}</p>')
        if show_answers and is_diagram:
            rows = "".join(
                f'<li><b style="color:var(--accent)">{i+1}.</b>'
                f'{diagram_svg(a["s"], a["p"], a.get("o"), a.get("c"))}</li>'
                for i, a in enumerate(answers))
            body = f'<ul class="b diagrows" style="list-style:none">{rows}</ul>'
        else:
            mid = (len(items) + 1) // 2
            inline = bool(slide.get("answerInline"))
            def col(start, chunk):
                out = ""
                for i, it in enumerate(chunk):
                    n = start + i
                    ans = ""
                    if show_answers and not is_diagram and n - 1 < len(answers):
                        if inline:
                            ans = f' <span class="ansinline">{fmt(answers[n-1])}</span>'
                        else:
                            ans = f'<div class="ansline">{fmt(answers[n-1])}</div>'
                    out += f'<li><b style="color:var(--accent)">{n}.</b> {fmt(it)}{ans}</li>'
                return out
            left = f'<ul class="b" style="list-style:none">{col(1, items[:mid])}</ul>'
            right = f'<ul class="b" style="list-style:none">{col(mid+1, items[mid:])}</ul>'
            body = f'<div class="cols">{left}{right}</div>'
        return f'<section class="slide">{tag}{head}{body}{foot}</section>'
    if t == "analysis":
        intro = f'<p class="instr">{fmt(slide["intro"])}</p>' if slide.get("intro") else ""
        rows = ""
        for r in slide["rows"]:
            svg = diagram_svg(r["s"], r.get("p", ""), r.get("o"), r.get("c"),
                              smod=r.get("smod"), pmod=r.get("pmod"), omod=r.get("omod"),
                              sappo=r.get("sappo"), sclause=r.get("sclause"),
                              pclause=r.get("pclause"), oclause=r.get("oclause"))
            sent = f'<div class="asent">{fmt(r["sentence"])}</div>' if r.get("sentence") else ""
            rows += (f'<div class="arow"><div class="adiag">{svg}</div>'
                     f'<div class="anote">{sent}<div>{fmt(r["note"])}</div></div></div>')
        return (f'<section class="slide"><h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'{intro}<div class="arows">{rows}</div>{foot}</section>')
    if t == "questions":
        answers = slide.get("answers") or []
        tag = '<div class="anskey">Answer Key</div>' if show_answers else ''
        lis = ""
        for i, q in enumerate(slide["items"]):
            ans = ""
            if show_answers and i < len(answers):
                ans = f' <span class="qans">{fmt(answers[i])}</span>'
            lis += f"<li>{fmt(q)}{ans}</li>"
        qcls = "q tight" if show_answers else "q"
        return (f'<section class="slide">{tag}<h2 class="h">Questions</h2><hr class="dbl">'
                f'<ol class="{qcls}">{lis}</ol>{foot}</section>')
    if t == "table":
        rows = ""
        for r in slide["rows"]:
            exs = f'<div class="tex">{fmt(r["examples"])}</div>' if r.get("examples") else ""
            rows += (f'<tr><td class="tlabel">{esc(r["label"])}</td>'
                     f'<td class="tdesc">{fmt(r["text"])}{exs}</td></tr>')
        return (f'<section class="slide"><h2 class="h">{esc(slide["heading"])}</h2><hr class="dbl">'
                f'<table class="ctable{" dense" if len(slide["rows"]) > 3 else ""}">{rows}</table>{foot}</section>')
    return ""


def build(lesson_path: Path, theme_name="light") -> Path:
    theme = get_theme(theme_name)
    _BRAND["eyebrow"] = theme.get("eyebrow", "")
    _BRAND["motto"] = theme.get("motto", "")
    data = json.loads(lesson_path.read_text())
    source = data.get("source", "")
    parts = []
    for s in data["slides"]:
        parts.append(render(s, source))
        if s["type"] in ("practice", "questions") and s.get("answers"):
            parts.append(render(s, source, show_answers=True))
    slides = "\n".join(parts)
    css = font_faces(theme) + root_vars(theme) + CSS_BODY
    doc = (f'<title>{esc(data["title"])} — Slides Preview</title>'
           f'<meta name="description" content="{esc(source)}">'
           f'<style>{css}</style><div class="deck">{slides}</div>')
    out_dir = Path(__file__).resolve().parent / "build"
    out_dir.mkdir(exist_ok=True)
    suffix = "" if theme_name == "light" else f"-{theme_name}"
    out_path = out_dir / f"{numbered_stem(data['lesson'], suffix)}.html"
    out_path.write_text(doc)
    return out_path


def resolve(arg: str) -> Path:
    p = Path(arg)
    if p.suffix == ".json" and p.exists():
        return p
    cand = Path(__file__).resolve().parents[3] / "content" / "grammar" / "lessons" / f"{arg}.json"
    if cand.exists():
        return cand
    raise SystemExit(f"Lesson not found: {arg}")


if __name__ == "__main__":
    lesson, theme = "the-verb", "light"
    for a in sys.argv[1:]:
        if a in THEMES:
            theme = a
        else:
            lesson = a
    out = build(resolve(lesson), theme)
    print(f"wrote {out}  (theme: {theme})")
