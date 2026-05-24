export function truncate(text: string, maxLength: number): string {
  return text.length > maxLength ? text.slice(0, maxLength) + "…" : text
}

// True if the string contains a glyph that triggers a Pango fallback font
// (and therefore a taller line-height that would stretch the bar). The bar's
// primary font is JetBrainsMono Nerd Font; emoji/dingbats/CJK pull in fonts
// with different metrics. Callers shrink the label's font-size when this
// returns true so the fallback's line-height fits within the bar's normal
// envelope set by surrounding chevrons/buttons.
const TALL_GLYPH_RE =
  /[‍☀-➿⬀-⯿　-鿿가-힯\uD800-\uDFFF︀-️]/

export function hasTallGlyphs(text: string): boolean {
  return TALL_GLYPH_RE.test(text)
}
