"""Color themes shared by generate_deck.py (pptx) and preview.py (html).

Each theme is a dict of hex strings (no leading #). Tokens:
  paper    slide background
  ink      body text
  accent   headings, item numbers, rules, "Answer Key" tag
  muted    footer, instructions, eyebrow
  rule     thin rule line / slide border
  answer   plain-text answer color (kept identical across all answers)
  diagram  sentence-diagram lines + words
  body_bg  page background behind the slides (html preview only)
  eyebrow  small-caps wordmark on the title slide
  motto    optional line beneath the title (blank to omit)

Font tokens:
  head_font  display/heading face (name must exist in PowerPoint/Google Slides)
  body_font  body face
  fonts      {family: repo-root-relative .ttf path} to embed in the HTML preview
             (Google Slides already has Cinzel / EB Garamond; the preview needs them inlined)
"""

_GEORGIA = {"head_font": "Georgia", "body_font": "Georgia", "fonts": {}}

# Two production themes:
#   light  — warm cream, Harvey letterpress; low-glare on a TV screen.
#   lyceum — the house brand (dark crimson); reads well projected on a chalkboard.
THEMES = {
    "light": {
        "paper":   "F5EFE3",
        "ink":     "23201B",
        "accent":  "7B2233",
        "muted":   "6E6456",
        "rule":    "CBBEA6",
        "answer":  "7B2233",
        "diagram": "23201B",
        "body_bg": "E4DDCC",
        "eyebrow": "HARVEY'S LANGUAGE COURSE",
        "motto":   "",
        **_GEORGIA,
    },
    # The Timpson Lyceum house brand — mirrors edu-web globals.css and
    # edu-ios Theme.swift: near-black crimson field, crimson surfaces,
    # gold-leaf accents, parchment text, Cinzel + EB Garamond.
    "lyceum": {
        "paper":   "190808",   # crimson-900 surface
        "ink":     "F5ECD8",   # parchment
        "accent":  "DDB954",   # gold-300 — THE brand color
        "muted":   "C4AF8E",   # parchment-dim / inkSoft
        "rule":    "4A1A1A",   # crimson-700 border
        "answer":  "E8CB7E",   # champagne (gold-200) — lighter than the heading gold
        "diagram": "F5ECD8",   # parchment, chalk-on-crimson
        "body_bg": "0F0404",   # crimson-950 page
        "eyebrow": "THE TIMPSON LYCEUM",
        "motto":   "Docendo Discimus  ·  by teaching, we learn",
        "head_font": "Cinzel",
        "body_font": "EB Garamond",
        "fonts": {
            "Cinzel":      "edu-ios/Resources/Fonts/Cinzel.ttf",
            "EB Garamond": "edu-ios/Resources/Fonts/EBGaramond.ttf",
        },
    },
}


def get_theme(name):
    if name not in THEMES:
        raise SystemExit(f"Unknown theme '{name}'. Choose from: {', '.join(THEMES)}")
    return THEMES[name]
