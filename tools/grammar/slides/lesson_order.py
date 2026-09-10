"""Canonical lesson number for each slide-lesson slug.

Numbers follow the course sequence (L1..L19), matching the numbered homework
drills in content/grammar/drills/lesson-NN.json. Generated files are prefixed
with the zero-padded number (e.g. 02_the-noun.pptx) so lessons sort and are
easy to locate. Add new lessons here.
"""

LESSON_NUMBERS = {
    "foundations": 1,
    "the-noun": 2,
    "the-verb": 3,
    "adjectives-participles": 4,
    "pronouns-1": 5,
    "pronouns-2": 6,
    "the-adverb": 7,
    "prepositions-phrases": 8,
    "conjunctions": 9,
    "sentences-interjection": 10,
    "noun-in-depth": 11,
    "pronouns-adjectives-depth": 12,
    "verb-depth-1": 13,
    "verb-depth-2": 14,
    "adverbs-to-interjections-depth": 15,
    "advanced-analysis": 16,
    "syntax-letters": 17,
    "punctuation": 18,
    "reference-verbs-capitals": 19,
}


def numbered_stem(slug, suffix=""):
    """Return the output filename stem, prefixed with the zero-padded lesson
    number when known (e.g. numbered_stem('the-noun') -> '02_the-noun').
    Falls back to the bare slug for any unmapped lesson."""
    n = LESSON_NUMBERS.get(slug)
    prefix = f"{n:02d}_" if n else ""
    return f"{prefix}{slug}{suffix}"
