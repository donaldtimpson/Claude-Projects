// Inline Cinzel + EB Garamond into fonts.css so a plate renders identically offline.
// The TTFs live in the iOS app's bundle; the web app loads the same faces from Google Fonts.
const { readFileSync, writeFileSync } = require("node:fs");
const { join } = require("node:path");
const fonts = join(__dirname, "..", "..", "..", "edu-ios", "Resources", "Fonts");
const b64 = (f) => readFileSync(join(fonts, f)).toString("base64");
writeFileSync(
  join(__dirname, "fonts.css"),
  `@font-face{font-family:'Cinzel';src:url(data:font/ttf;base64,${b64("Cinzel.ttf")}) format('truetype');font-weight:400 700;}\n` +
  `@font-face{font-family:'EBG';src:url(data:font/ttf;base64,${b64("EBGaramond.ttf")}) format('truetype');font-weight:400 700;}\n`,
);
console.log("wrote tools/category-plate/fonts.css");
