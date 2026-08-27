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

`history`, `mathematics`, `philosophy`, `science` are raster illustrations in an engraved
style. `language.png` was composed as vector + type and rendered headless from
`tools/category-plate/` — it follows the same template but does not have the engraved
depth of the other four, so it is the one to replace first if the set is ever redone.
