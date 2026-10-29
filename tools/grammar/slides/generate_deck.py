#!/usr/bin/env python3
"""Lesson JSON -> .pptx deck.

Reads a lesson file from lessons/<name>.json and writes build/<name>.pptx.
The .pptx is designed to convert cleanly into native Google Slides on upload.

Usage:
    python generate_deck.py the-verb
    python generate_deck.py lessons/the-verb.json
"""
import json
import math
import re
import sys
from pathlib import Path

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.dml import MSO_LINE_DASH_STYLE

from themes import THEMES, get_theme
from lesson_order import numbered_stem

# ---- Theme (colors + brand set by apply_theme before a build) --------------
INK = ACCENT = MUTED = PAPER = RULE = ANSWER = DIAGRAM = None
EYEBROW = MOTTO = ""
HEAD_FONT = BODY_FONT = "Georgia"


def apply_theme(theme):
    global INK, ACCENT, MUTED, PAPER, RULE, ANSWER, DIAGRAM
    global EYEBROW, MOTTO, HEAD_FONT, BODY_FONT
    INK = RGBColor.from_string(theme["ink"])
    ACCENT = RGBColor.from_string(theme["accent"])
    MUTED = RGBColor.from_string(theme["muted"])
    PAPER = RGBColor.from_string(theme["paper"])
    RULE = RGBColor.from_string(theme["rule"])
    ANSWER = RGBColor.from_string(theme["answer"])
    DIAGRAM = RGBColor.from_string(theme["diagram"])
    EYEBROW = theme.get("eyebrow", "")
    MOTTO = theme.get("motto", "")
    HEAD_FONT = theme.get("head_font", "Georgia")
    BODY_FONT = theme.get("body_font", "Georgia")

EMU = 914400
SLIDE_W = Inches(13.333)
SLIDE_H = Inches(7.5)
MARGIN = Inches(0.9)


def _blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def _bg(slide):
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = PAPER


def _box(slide, left, top, width, height):
    tb = slide.shapes.add_textbox(left, top, width, height)
    tf = tb.text_frame
    tf.word_wrap = True
    return tb, tf


def _run(p, text, *, size, color=None, bold=False, italic=False, font=None):
    r = p.add_run()
    r.text = text
    f = r.font
    f.size = Pt(size)
    f.bold = bold
    f.italic = italic
    f.name = font if font is not None else BODY_FONT
    f.color.rgb = color if color is not None else INK
    return r


_EMPH = re.compile(r"\*\*([^*]+)\*\*|\*([^*]+)\*")


def _richrun(p, text, *, size, color=None, bold=False, italic=False, font=None):
    """Add runs for `text`, rendering *word* spans in italic and **word** spans
    in bold accent. House rules: a word referred to as a word (use-mention) is
    wrapped in *asterisks*; **double asterisks** highlight the word an example
    sentence is showing (e.g. the relative pronoun)."""
    text = str(text)
    pos = 0
    for m in _EMPH.finditer(text):
        if m.start() > pos:
            _run(p, text[pos:m.start()], size=size, color=color, bold=bold,
                 italic=italic, font=font)
        if m.group(1) is not None:
            _run(p, m.group(1), size=size, color=ACCENT, bold=True, italic=italic, font=font)
        else:
            _run(p, m.group(2), size=size, color=color, bold=bold, italic=True, font=font)
        pos = m.end()
    if pos < len(text) or pos == 0:
        _run(p, text[pos:], size=size, color=color, bold=bold, italic=italic, font=font)


def _hanging_indent(p, amount):
    """Give a paragraph a hanging indent (wrapped lines indent by `amount` EMU)."""
    pPr = p._p.get_or_add_pPr()
    pPr.set("marL", str(int(amount)))
    pPr.set("indent", str(-int(amount)))


def _rule(slide, top, left=MARGIN, width=None, thickness=Pt(2), color=None):
    if width is None:
        width = SLIDE_W - 2 * MARGIN
    ln = slide.shapes.add_shape(1, left, top, width, thickness)  # rectangle
    ln.fill.solid()
    ln.fill.fore_color.rgb = color if color is not None else RULE
    ln.line.fill.background()
    ln.shadow.inherit = False
    return ln


def _double_rule(slide, top, left=MARGIN, width=None):
    """Thick-then-thin letterpress rule, echoing Harvey's title pages."""
    _rule(slide, top, left=left, width=width, thickness=Pt(3), color=ACCENT)
    _rule(slide, top + Pt(5), left=left, width=width, thickness=Pt(1), color=RULE)


def _line(slide, x1, y1, x2, y2, color=None, width=Pt(1.5), dashed=False):
    # A freeform, not a connector: Google Slides fails to import python-pptx
    # connector shapes (<p:cxnSp>), while Keynote/PowerPoint accept them.
    ff = slide.shapes.build_freeform(x1, y1, scale=1.0)
    ff.add_line_segments([(x2, y2)], close=False)
    cn = ff.convert_to_shape()
    cn.fill.background()
    cn.line.color.rgb = color if color is not None else DIAGRAM
    cn.line.width = width
    if dashed:
        cn.line.dash_style = MSO_LINE_DASH_STYLE.DASH
    cn.shadow.inherit = False
    return cn


# ---- Reed-Kellogg sentence diagram -----------------------------------------
DIAG_CHW = int(Inches(0.115))   # approx width per character at 18pt Georgia
DIAG_PAD = int(Inches(0.17))    # padding on each side of a word (gap for dividers)


def _slot_w(text):
    return len(text) * DIAG_CHW + 2 * DIAG_PAD


def _diag_word(slide, left, base_y, width, text):
    h = Inches(0.32)
    tb = slide.shapes.add_textbox(left, base_y - h, width, h)
    tf = tb.text_frame
    tf.word_wrap = False
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = Pt(2)
    tf.vertical_anchor = MSO_ANCHOR.BOTTOM
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    _run(p, text, size=18, color=DIAGRAM)


def _mlist(m):
    """Normalize a modifier field (None | str | list) to a list of words."""
    if not m:
        return []
    return [m] if isinstance(m, str) else list(m)


def _appo(a):
    """Normalize an appositive field (None | str | {"word", "mod"}) to a dict."""
    if not a:
        return None
    if isinstance(a, str):
        return {"word": a, "mod": []}
    return {"word": a["word"], "mod": _mlist(a.get("mod"))}


def _draw_mods(slide, cx, base_y, words):
    """Hang one or more adjective-element modifiers — articles, adjectives,
    possessives, demonstratives — on down-right slants beneath a word centered
    at cx. Several modifiers step to the right, the way Harvey stacks them
    (e.g. 'an' and 'easy' both under 'task')."""
    dx, dy, gap, spread = Inches(0.24), Inches(0.34), Inches(0.06), Inches(0.09)
    n = len(words)
    wx = cx + dx
    prev = 0
    for i, word in enumerate(words):
        w = _slot_w(word)
        if i:
            wx += prev / 2 + w / 2 + gap
        anchor = cx + int((i - (n - 1) / 2) * spread)   # slant tops fan under the noun
        _line(slide, anchor, base_y, wx, base_y + dy)
        _diag_word(slide, wx - w / 2, base_y + dy + Inches(0.30), w, word)
        prev = w



# A modifier may also be a phrase — {"prep", "obj", "mod", "o", "omod"} — hung
# modern Reed-Kellogg style: the preposition on a slant, its object on a short
# line beneath (with its own modifiers, and an object after a divider for an
# infinitive like "to write | letter"). An infinitive keeps "to" with its verb
# in `obj` (Harvey: the two parts are not separated) and omits `prep`.
PH_DX, PH_DY = int(Inches(0.36)), int(Inches(0.55))   # phrase slant run / drop
MOD_DX, MOD_GAP, MOD_LEAD = int(Inches(0.24)), int(Inches(0.14)), int(Inches(0.10))


def _is_phrase(m):
    return isinstance(m, dict)


def _mods_right(cx, words):
    """Rightmost x reached by _draw_mods(cx, words), without drawing."""
    gap, wx, prev, right = Inches(0.06), cx + MOD_DX, 0, cx
    for i, word in enumerate(words):
        w = _slot_w(word)
        if i:
            wx += prev / 2 + w / 2 + gap
        right = max(right, wx + w / 2)
        prev = w
    return right


def _mod_plan(items):
    """Lay out a slot's modifiers left to right when any is a phrase, each
    starting clear of the one before so no slant crosses another's line.
    Returns ([(item, anchor offset)], span) with offsets from the slot's left."""
    plan, a = [], MOD_LEAD
    for m in items:
        plan.append((m, a))
        if _is_phrase(m):
            hx = a + PH_DX
            wobj = _slot_w(m["obj"])
            end = hx + wobj + (_slot_w(m["o"]) if m.get("o") else 0)
            end = max(end, _mods_right(hx + wobj / 2, _mlist(m.get("mod"))))
            if m.get("o"):
                end = max(end, _mods_right(hx + wobj + _slot_w(m["o"]) / 2, _mlist(m.get("omod"))))
        else:
            w = _slot_w(m)
            end = a + max(MOD_DX, w / 2) + w / 2
        a = int(end + MOD_GAP)
    return plan, a


def _wslot(word, mods):
    """A slot's baseline width: the word's, or wider to seat its phrases."""
    ms = _mlist(mods)
    w = _slot_w(word)
    if any(_is_phrase(m) for m in ms):
        w = max(w, _mod_plan(ms)[1])
    return w


def _draw_slot_mods(slide, left, width, base_y, mods):
    """Hang a slot's modifiers: centered under the word as before when they are
    all single words; laid out left to right when a phrase is among them."""
    ms = _mlist(mods)
    if not ms:
        return
    if not any(_is_phrase(m) for m in ms):
        _draw_mods(slide, left + width / 2, base_y, ms)
        return
    for m, off in _mod_plan(ms)[0]:
        a = left + off
        if not _is_phrase(m):
            w = _slot_w(m)
            c = a + max(MOD_DX, w / 2)
            _line(slide, int(a), base_y, int(c), base_y + Inches(0.34))
            _diag_word(slide, int(c - w / 2), base_y + Inches(0.64), w, m)
            continue
        hx, hy = a + PH_DX, base_y + PH_DY
        wobj = _slot_w(m["obj"])
        wo = _slot_w(m["o"]) if m.get("o") else 0
        _line(slide, int(a), base_y, int(hx), hy)                 # slant
        _line(slide, int(hx), hy, int(hx + wobj + wo), hy)        # object line
        _diag_word(slide, int(hx), hy, wobj, m["obj"])
        if m.get("o"):
            _line(slide, int(hx + wobj), hy - Inches(0.26), int(hx + wobj), hy)
            _diag_word(slide, int(hx + wobj), hy, wo, m["o"])
            if m.get("omod"):
                _draw_mods(slide, hx + wobj + wo / 2, hy, _mlist(m["omod"]))
        if m.get("mod"):
            _draw_mods(slide, hx + wobj / 2, hy, _mlist(m["mod"]))
        if m.get("prep"):
            # The preposition written along its slant, just above-right of the line.
            ang = math.atan2(PH_DY, PH_DX)
            off = Inches(0.13)
            mx = (a + hx) / 2 + math.sin(ang) * off
            my = (base_y + hy) / 2 - math.cos(ang) * off
            pw, ph = _slot_w(m["prep"]), Inches(0.3)
            tb = slide.shapes.add_textbox(int(mx - pw / 2), int(my - ph / 2), int(pw), int(ph))
            tb.rotation = math.degrees(ang)
            tf = tb.text_frame
            tf.word_wrap = False
            tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
            tf.vertical_anchor = MSO_ANCHOR.MIDDLE
            pp = tf.paragraphs[0]
            pp.alignment = PP_ALIGN.CENTER
            _run(pp, m["prep"], size=16, color=DIAGRAM)


def _has_phrase(*mods):
    return any(_is_phrase(m) for ms in mods for m in _mlist(ms))

CLAUSE_DROP = Inches(0.92)      # main baseline -> top of a hanging clause's diagram
CLAUSE_INSET = Inches(0.12)     # where a dashed connector meets its antecedent word


def _slot_layout(s, p, o=None, c=None, sappo=None, smod=None, pmod=None, omod=None):
    """(left edge, width) of the subject, predicate, and object slots, relative to
    the diagram's left — the same geometry _draw_diagram lays out."""
    ap = _appo(sappo)
    ws = _wslot(s, smod)
    sreg = ws + (_slot_w(f"({ap['word']})") if ap else 0)
    if c:
        wc, wp = _slot_w(c), _wslot(p, pmod)
        return {"s": (0, ws), "c": (sreg, wc), "p": (sreg + wc, wp)}
    wp = _wslot(p, pmod)
    out = {"s": (0, ws), "p": (sreg, wp)}
    if o:
        out["o"] = (sreg + wp, _wslot(o, omod))
    return out


def _clause_rel(cl):
    """Center of a clause's relative pronoun (the slot named by cl["rel"]),
    relative to the clause diagram's left edge."""
    slots = _slot_layout(cl["s"], cl.get("p", ""), cl.get("o"), cl.get("c"),
                         smod=cl.get("smod"), pmod=cl.get("pmod"), omod=cl.get("omod"))
    rl, rw = slots[cl.get("rel", "s")]
    return rl + rw / 2


def _clause_shift(s, p, o, c, sappo, clauses, mods=(None, None, None)):
    """How far to push the main line right so each hanging clause can sit with
    its relative straight beneath the antecedent's left end."""
    slots = _slot_layout(s, p, o, c, sappo, *mods)
    need = [_clause_rel(cl) - (slots[k][0] + CLAUSE_INSET)
            for k, cl in clauses.items() if cl and k in slots]
    return int(max([0] + need))


def _draw_clause(slide, left, base, ante, cl):
    """Hang a relative clause beneath its antecedent (modern Reed-Kellogg): the
    clause on its own baseline — its own subject | predicate — with a dashed line
    dropping straight from the antecedent's left end to the relative pronoun.
    An adverbial clause names the modified slot as its "rel" (usually "p") and
    may set `link`, the connective written beside the dashed line.
    `ante` is the antecedent's (left, width) relative to `left`. Returns the
    clause's right edge (EMU)."""
    anchor = left + ante[0] + CLAUSE_INSET
    cl_left = int(anchor - _clause_rel(cl))
    ctop = base + CLAUSE_DROP
    right = _draw_diagram(slide, cl_left, ctop, cl["s"], cl.get("p", ""), cl.get("o"),
                          cl.get("c"), smod=cl.get("smod"), pmod=cl.get("pmod"),
                          omod=cl.get("omod"))
    _line(slide, int(anchor), base, int(anchor), ctop + Inches(0.02), dashed=True)
    if cl.get("link"):
        # A connective (e.g. the *when* of an adverbial clause) written on the connector.
        lw = _slot_w(cl["link"])
        lx = int(anchor + Inches(0.06))
        _diag_word(slide, lx, base + Inches(0.58), lw, cl["link"])
        right = max(right, lx + lw)
    return right


def _draw_diagram(slide, left, top, s, p, o=None, c=None,
                  smod=None, pmod=None, omod=None, sappo=None,
                  sclause=None, pclause=None, oclause=None):
    """Baseline subject | predicate | object, or Harvey's copular form
    subject | copula : predicate when `c` is given. `smod`/`pmod`/`omod` hang
    adjective-element modifiers on slants beneath the subject, predicate-noun,
    or object (each a word or a list). `sappo` sets an appositive, drawn in
    parentheses on the baseline beside the subject (modern Reed-Kellogg), with
    its own modifier on a slant. `sclause`/`pclause`/`oclause` hang a relative
    clause beneath that slot (see _draw_clause); the main line shifts right to
    make room for it. Returns the right edge (EMU)."""
    left += _clause_shift(s, p, o, c, sappo, {"s": sclause, "p": pclause, "o": oclause},
                          (smod, pmod, omod))
    base = top + Inches(0.30)
    top_line = top + Inches(0.04)
    below = Inches(0.13)
    sm, pm, om = _mlist(smod), _mlist(pmod), _mlist(omod)
    ap = _appo(sappo)
    ws = _wslot(s, sm)
    appo_text = f"({ap['word']})" if ap else ""
    wappo = _slot_w(appo_text) if ap else 0
    sreg = ws + wappo   # subject region: subject word + any appositive, on the baseline

    def draw_subject():
        _diag_word(slide, left, base, ws, s)
        _draw_slot_mods(slide, left, ws, base, sm)
        if ap:
            _diag_word(slide, left + ws, base, wappo, appo_text)
            if ap["mod"]:
                _draw_mods(slide, left + ws + wappo / 2, base, ap["mod"])

    if c:
        # Harvey: "Iron | is : heavy" — copula set off from the predicate, not folded in.
        wc, wp = _slot_w(c), _wslot(p, pm)
        x1 = left + sreg
        x2 = x1 + wc
        xend = x2 + wp
        _line(slide, left, base, xend, base)            # baseline
        _line(slide, x1, top_line, x1, base + below)     # subject | (crosses, principal split)
        _line(slide, x2, top_line, x2, base)             # copula : predicate (stops at baseline)
        draw_subject()
        _diag_word(slide, x1, base, wc, c)
        _diag_word(slide, x2, base, wp, p)
        _draw_slot_mods(slide, x2, wp, base, pm)
        return _hang_clauses(slide, left, base, xend, s, p, o, c, sappo,
                             sclause, pclause, oclause, (sm, pm, om))
    wp = _wslot(p, pm)
    wo = _wslot(o, om) if o else 0
    x1 = left + sreg
    x2 = x1 + wp
    xend = x2 + wo
    _line(slide, left, base, xend, base)               # baseline
    _line(slide, x1, top_line, x1, base + below)        # subject | predicate (crosses)
    if o:
        _line(slide, x2, top_line, x2, base)            # predicate | object (stops)
    draw_subject()
    _diag_word(slide, x1, base, wp, p)
    if o:
        _diag_word(slide, x2, base, wo, o)
    _draw_slot_mods(slide, x1, wp, base, pm)
    if o:
        _draw_slot_mods(slide, x2, wo, base, om)
    return _hang_clauses(slide, left, base, xend, s, p, o, c, sappo,
                         sclause, pclause, oclause, (sm, pm, om))


def _hang_clauses(slide, left, base, xend, s, p, o, c, sappo, sclause, pclause, oclause,
                  mods=(None, None, None)):
    slots = _slot_layout(s, p, o, c, sappo, *mods)
    for key, cl in (("s", sclause), ("p", pclause), ("o", oclause)):
        if cl and key in slots:
            xend = max(xend, _draw_clause(slide, left, base, slots[key], cl))
    return xend


def _footer(slide, source):
    _, tf = _box(slide, MARGIN, SLIDE_H - Inches(0.6),
                 SLIDE_W - 2 * MARGIN, Inches(0.4))
    p = tf.paragraphs[0]
    _run(p, source, size=10, color=MUTED, italic=True)


def _heading(slide, text):
    _, tf = _box(slide, MARGIN, Inches(0.7),
                 SLIDE_W - 2 * MARGIN, Inches(1.0))
    p = tf.paragraphs[0]
    _run(p, text, size=34, color=ACCENT, bold=True, font=HEAD_FONT)
    _double_rule(slide, Inches(1.65))


# ---- Slide renderers -------------------------------------------------------
def render_title(slide, s, source):
    _bg(slide)
    # Eyebrow, small-caps, echoing the book's title page
    _, tfe = _box(slide, MARGIN, Inches(1.7), SLIDE_W - 2 * MARGIN, Inches(0.5))
    pe = tfe.paragraphs[0]
    pe.alignment = PP_ALIGN.CENTER
    _run(pe, EYEBROW, size=15, color=MUTED, bold=True, font=HEAD_FONT)

    _double_rule(slide, Inches(2.45), left=Inches(4.4), width=Inches(4.5))

    _, tf = _box(slide, MARGIN, Inches(2.7), SLIDE_W - 2 * MARGIN, Inches(2.2))
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    _run(p, s["title"], size=60, color=ACCENT, bold=True, font=HEAD_FONT)
    if s.get("subtitle"):
        p2 = tf.add_paragraph()
        p2.alignment = PP_ALIGN.CENTER
        p2.space_before = Pt(18)
        _run(p2, s["subtitle"], size=22, color=MUTED, italic=True)

    _double_rule(slide, Inches(5.05), left=Inches(4.4), width=Inches(4.5))

    if MOTTO:
        _, tfm = _box(slide, MARGIN, Inches(5.4), SLIDE_W - 2 * MARGIN, Inches(0.5))
        pm = tfm.paragraphs[0]
        pm.alignment = PP_ALIGN.CENTER
        _run(pm, MOTTO, size=15, color=ACCENT, italic=True)

    _footer(slide, source)


def render_definition(slide, s, source):
    _bg(slide)
    _heading(slide, s["term"])
    _, tf = _box(slide, MARGIN, Inches(2.1),
                 SLIDE_W - 2 * MARGIN, Inches(1.6))
    p = tf.paragraphs[0]
    _richrun(p, s["text"], size=30, color=INK, italic=True, font=BODY_FONT)

    if s.get("examples"):
        _, tf2 = _box(slide, MARGIN, Inches(3.9),
                      SLIDE_W - 2 * MARGIN, Inches(2.6))
        head = tf2.paragraphs[0]
        _run(head, "EXAMPLES", size=15, color=ACCENT, bold=True)
        for ex in s["examples"]:
            p = tf2.add_paragraph()
            p.space_before = Pt(6)
            _run(p, "•  ", size=22, color=ACCENT, bold=True)
            _richrun(p, ex, size=22, color=INK)
    _footer(slide, source)


def render_concept(slide, s, source):
    _bg(slide)
    _heading(slide, s["heading"])
    _, tf = _box(slide, MARGIN, Inches(2.0),
                 SLIDE_W - 2 * MARGIN, Inches(4.6))
    first = True
    for b in s["bullets"]:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.space_after = Pt(12)
        _run(p, "•  ", size=24, color=ACCENT, bold=True)
        _richrun(p, b, size=24, color=INK)
    _footer(slide, source)


def render_practice(slide, s, source, show_answers=False):
    _bg(slide)
    _heading(slide, s["heading"])
    if show_answers:
        _, tft = _box(slide, SLIDE_W - MARGIN - Inches(2.6), Inches(0.92),
                      Inches(2.6), Inches(0.4))
        pt = tft.paragraphs[0]
        pt.alignment = PP_ALIGN.RIGHT
        _run(pt, "ANSWER KEY", size=14, color=ACCENT, bold=True)

    _, tf = _box(slide, MARGIN, Inches(1.95),
                 SLIDE_W - 2 * MARGIN, Inches(1.1))
    p = tf.paragraphs[0]
    _richrun(p, s["instruction"], size=18, color=MUTED, italic=True)

    answers = s.get("answers") or []
    is_diagram = bool(answers) and isinstance(answers[0], dict)

    if show_answers and is_diagram:
        _practice_diagram_answers(slide, s, answers)
    else:
        _practice_item_columns(slide, s, answers if show_answers else None)
    _footer(slide, source)


def _practice_item_columns(slide, s, answers):
    """Two columns of numbered items. Answers sit on their own line beneath
    each item, unless the slide sets "answerInline" (then they follow inline —
    good for long sentences with a one-word answer)."""
    items = s["items"]
    inline = s.get("answerInline", False)
    mid = (len(items) + 1) // 2
    cols = [items[:mid], items[mid:]]
    gap = Inches(0.3)                         # tighter gap between columns
    usable = SLIDE_W - MARGIN - Inches(0.6)   # narrower right cushion -> wider columns
    col_w = (usable - gap) / 2
    for ci, col in enumerate(cols):
        left = MARGIN + ci * (col_w + gap)
        _, tf = _box(slide, left, Inches(3.1), col_w, Inches(3.5))
        first = True
        for i, it in enumerate(col):
            n = ci * mid + i + 1
            p = tf.paragraphs[0] if first else tf.add_paragraph()
            first = False
            p.space_after = Pt(10 if (not answers or inline) else 4)
            _run(p, f"{n}.  ", size=22, color=ACCENT, bold=True)
            _richrun(p, it, size=22, color=INK)
            if answers and n - 1 < len(answers):
                if inline:
                    _run(p, "   ", size=22, color=ANSWER)
                    _richrun(p, answers[n - 1], size=22, color=ANSWER, bold=True)
                else:
                    pa = tf.add_paragraph()
                    pa.space_after = Pt(14)
                    _run(pa, "     ", size=20, color=ANSWER)   # small hanging indent
                    _richrun(pa, answers[n - 1], size=20, color=ANSWER, bold=True)


def _practice_diagram_answers(slide, s, answers):
    """Single column of Reed-Kellogg diagrams, one per item."""
    items = s["items"]
    y = Inches(3.15)
    row_h = Inches(0.72)
    for i, a in enumerate(answers):
        _, tf = _box(slide, MARGIN, y - Inches(0.02), Inches(0.5), Inches(0.4))
        _run(tf.paragraphs[0], f"{i + 1}.", size=18, color=ACCENT, bold=True)
        _draw_diagram(slide, MARGIN + Inches(0.55), y,
                      a["s"], a["p"], a.get("o"), a.get("c"))
        y += row_h


def render_questions(slide, s, source, show_answers=False):
    _bg(slide)
    _heading(slide, "Questions")
    if show_answers:
        _, tft = _box(slide, SLIDE_W - MARGIN - Inches(2.6), Inches(0.92),
                      Inches(2.6), Inches(0.4))
        pt = tft.paragraphs[0]
        pt.alignment = PP_ALIGN.RIGHT
        _run(pt, "ANSWER KEY", size=14, color=ACCENT, bold=True)

    answers = s.get("answers") or []
    # The answer version packs a lot in, so it starts higher and sits tighter.
    top = Inches(1.75) if show_answers else Inches(1.9)
    _, tf = _box(slide, MARGIN, top, SLIDE_W - 2 * MARGIN, Inches(5.2))
    first = True
    for i, q in enumerate(s["items"], 1):
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.space_after = Pt(4 if show_answers else 14)
        if show_answers:
            p.line_spacing = 0.9
        _run(p, f"{i}.  ", size=22, color=ACCENT, bold=True)
        _richrun(p, q, size=22, color=INK)
        # Answer runs inline on the same line; hanging indent keeps a wrap aligned.
        if show_answers and i - 1 < len(answers):
            _hanging_indent(p, int(Inches(0.42)))
            _run(p, "   ", size=20, color=INK)
            _richrun(p, answers[i - 1], size=20, color=ANSWER, bold=True)
    _footer(slide, source)


def render_table(slide, s, source):
    """A classification table: a bold label column beside a description (and
    optional examples), a light divider between the columns and a rule between
    rows — a Harvey-style comparison of a handful of kinds."""
    _bg(slide)
    _heading(slide, s["heading"])
    rows = s["rows"]
    top = Inches(2.25)
    row_h = min(Inches(1.4), int((Inches(6.8) - top) / len(rows)))
    label_w = Inches(2.7)
    gap = Inches(0.45)
    desc_left = MARGIN + label_w + gap
    desc_w = SLIDE_W - MARGIN - desc_left
    div_x = MARGIN + label_w + Inches(0.225)
    _line(slide, div_x, top + Inches(0.05),
          div_x, top + row_h * len(rows) - Inches(0.1), color=MUTED, width=Pt(1))
    for i, r in enumerate(rows):
        y = top + row_h * i
        _, tfl = _box(slide, MARGIN, y, label_w, row_h)
        tfl.vertical_anchor = MSO_ANCHOR.MIDDLE
        _run(tfl.paragraphs[0], r["label"], size=27, color=ACCENT, bold=True, font=HEAD_FONT)
        _, tfd = _box(slide, desc_left, y, desc_w, row_h)
        tfd.vertical_anchor = MSO_ANCHOR.MIDDLE
        _richrun(tfd.paragraphs[0], r["text"], size=21, color=INK, font=BODY_FONT)
        if r.get("examples"):
            pe = tfd.add_paragraph()
            pe.space_before = Pt(5)
            _richrun(pe, r["examples"], size=17, color=MUTED, italic=True, font=BODY_FONT)
        if i < len(rows) - 1:
            _rule(slide, y + row_h, left=MARGIN, width=SLIDE_W - 2 * MARGIN,
                  thickness=Pt(0.75), color=MUTED)
    _footer(slide, source)


def render_analysis(slide, s, source):
    """A single teaching slide: each sentence's diagram beside a note naming how
    its pronouns function — no prompt/answer split."""
    _bg(slide)
    _heading(slide, s["heading"])
    y = Inches(1.95)
    if s.get("intro"):
        _, tfi = _box(slide, MARGIN, Inches(1.75), SLIDE_W - 2 * MARGIN, Inches(0.55))
        _run(tfi.paragraphs[0], s["intro"], size=18, color=MUTED, italic=True)
        y = Inches(2.5)
    rows = s["rows"]
    # A row with a hanging clause needs room for a second baseline.
    heights = [Inches(2.2) if any(r.get(k) for k in ("sclause", "pclause", "oclause"))
               else Inches(2.0) if _has_phrase(r.get("smod"), r.get("pmod"), r.get("omod"))
               else Inches(1.5) for r in rows]
    avail = Inches(6.8) - y
    if sum(heights) > avail:
        heights = [int(h * avail / sum(heights)) for h in heights]
    # The note column sits right of the widest diagram (phrases can run long).
    def diag_w(r):
        mods = (r.get("smod"), r.get("pmod"), r.get("omod"))
        slots = _slot_layout(r["s"], r.get("p", ""), r.get("o"), r.get("c"), r.get("sappo"), *mods)
        shift = _clause_shift(r["s"], r.get("p", ""), r.get("o"), r.get("c"), r.get("sappo"),
                              {k: r.get(k + "clause") for k in "spo"}, mods)
        return shift + max(l + w for l, w in slots.values())
    note_x = max(MARGIN + Inches(5.3), MARGIN + Inches(0.55) + max(diag_w(r) for r in rows))
    note_w = SLIDE_W - MARGIN - note_x
    top = y
    for r, row_h in zip(rows, heights):
        _draw_diagram(slide, MARGIN + Inches(0.2), top + Inches(0.1),
                      r["s"], r.get("p", ""), r.get("o"), r.get("c"),
                      smod=r.get("smod"), pmod=r.get("pmod"), omod=r.get("omod"),
                      sappo=r.get("sappo"), sclause=r.get("sclause"),
                      pclause=r.get("pclause"), oclause=r.get("oclause"))
        _, tfn = _box(slide, note_x, top - Inches(0.1), note_w, row_h)
        tfn.vertical_anchor = MSO_ANCHOR.MIDDLE
        if r.get("sentence"):
            ps = tfn.paragraphs[0]
            ps.space_after = Pt(5)
            _richrun(ps, r["sentence"], size=17, color=ACCENT, bold=True)
            _richrun(tfn.add_paragraph(), r["note"], size=15, color=INK)
        else:
            _richrun(tfn.paragraphs[0], r["note"], size=16, color=INK)
        top += row_h
    _footer(slide, source)


RENDERERS = {
    "title": render_title,
    "definition": render_definition,
    "concept": render_concept,
    "practice": render_practice,
    "questions": render_questions,
    "table": render_table,
    "analysis": render_analysis,
}


def build(lesson_path: Path, theme_name="light") -> Path:
    apply_theme(get_theme(theme_name))
    data = json.loads(lesson_path.read_text())
    source = data.get("source", "")

    prs = Presentation()
    prs.slide_width = SLIDE_W
    prs.slide_height = SLIDE_H

    for s in data["slides"]:
        slide = _blank(prs)
        RENDERERS[s["type"]](slide, s, source)
        # A practice/questions slide with answers is followed by an "Answer Key" slide.
        if s["type"] == "practice" and s.get("answers"):
            render_practice(_blank(prs), s, source, show_answers=True)
        elif s["type"] == "questions" and s.get("answers"):
            render_questions(_blank(prs), s, source, show_answers=True)

    out_dir = Path(__file__).resolve().parent / "build"
    out_dir.mkdir(exist_ok=True)
    suffix = "" if theme_name == "light" else f"-{theme_name}"
    out_path = out_dir / f"{numbered_stem(data['lesson'], suffix)}.pptx"
    prs.save(str(out_path))
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
