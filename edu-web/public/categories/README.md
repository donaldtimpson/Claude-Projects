# Category plates

One image per category, named `{slug}.png` — the slug of the `Category` row, not its
display name. `CategoryImageSlot` (`app/(site)/page.tsx`) and the category header
(`app/(site)/categories/[slug]/page.tsx`) both build the path from the slug and render it
with **no existence check**, so a category without a plate shows a broken image on the
home page. Add the file in the same commit as the category.

**Size: 832 × 466** (16:9; the home-page card is `aspect-video`).

## House template

Left third is type, right two-thirds is the illustration, over deep crimson with a gold
double-rule frame and corner filigree:

- lyre-in-laurel emblem, then `THE TIMPSON LYCEUM` in Cinzel small caps
- the category name, large, in gold-gradient Cinzel
- a tagline in gold small caps — "THE LIFE OF THE MIND" (philosophy), "THE LANGUAGE OF
  REASON" (mathematics), "THE RULE OF SPEECH" (language)
- a short quotation in its original language, EB Garamond italic, with the source in
  small caps beneath
- an illustration on the right in sepia/gold: a bust and scroll for philosophy, Euclid
  and dividers for mathematics, a book and quill for language

Palette is the site's own (`app/globals.css`): crimson `#0f0404`–`#4a1a1a`, gold
`#9a7209`–`#e8cb7e`, parchment `#f5ecd8`.

## Provenance

All five are raster illustrations in an engraved style, generated from a prompt describing
the series (size, palette, engraving style, and the objects for that subject) rather than
drawn. Ask for the whole family at once, or for "one more to go with the other four" in the
same conversation, so the palette and layout stay consistent. Source renders come out around
1280x720 or larger; resample to 832 wide and crop to 466.

Proofread any Latin or Greek in the artwork letter by letter before committing it — dropped
and doubled letters are the usual failure, and text baked into an illustration cannot be
fixed later without regenerating the whole plate.
