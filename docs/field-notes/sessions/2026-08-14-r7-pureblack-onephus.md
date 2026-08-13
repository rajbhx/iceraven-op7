# Session digest — 2026-08-14 — r7 pure-black everywhere + OnePlus red accent

## Problems solved
- **P** user rejected r6 as "a mix of gray and pureblack" (screenshot showed #1A1A1A card rows on the pure-black Settings page)
  cause: r6 container scale lifted off pure black (lowest #0A0A0A < container #1A1A1A < highest #242424) plus layer_color_2/3 and outline tokens still referenced dark greys; every content surface was lit gray on black
  solution: r7 collapses the ENTIRE dark-theme surface scale to #000000 (background/surface/dim/surface_variant/surface_bright, all surface_container_*, layer_color_2, layer_color_3, splash #210340->#000000) and carries structure with hairlines instead of lit fills: outline #2A2A2A, outline_variant #242424, settings row card gets a 1dp #242424 stroke around its pure-black fill (op7_preference_row_background); result = true pure-black everywhere with cards still distinguishable
  section: F
  tags: amoled, pureblack, theme, hairlines, resource-only, r7
- **P** user wants the browser to feel OnePlus-branded, not Mozilla-violet
  cause: fx_mobile_primary + dark-mode accent family map to nova/photon violet palette in values/colors.xml and values-night/colors.xml
  solution: new 006-op7-onephone-red-accent.patch remaps the accent family to OnePlus red #EB0029 (night primary #EB0029, primary_container #FF4D000F, primary_inverse #FFFF3346, accent_normal_theme #EB0029, high-contrast #FFFF3346, fill-link/cursor/dashboard progress #EB0029; day primary #EB0029, container #FFFFD9DE, inverse #FFFF4D5E); private-mode violet identity kept intact; day accent_normal_theme untouched because it is text color (photonInk20), not brand accent
  section: F
  tags: onephus, brand, red-accent, colors, r7
- **P** 005 and 006 both edit values-night/colors.xml — risk of inter-patch hunk overlap breaking the sequence
  cause: sequential git apply needs non-overlapping context lines
  solution: generated 005 v3 and 006 as separate commits in a scratch git repo from pristine upstream files, exported real-blob diffs, then verified on a fresh baseline: 005 check+apply OK, 006 check+apply OK, final tree byte-identical to target; no overlap (005 hunks at lines 17-60, 006 at 4-11 + 95-119)
  section: E
  tags: patch-generation, git-apply, validation

## Notes
- #EB0029 on #000000 ≈ 4.6:1 contrast — passes AA for normal-size accent text; safe for links/buttons/icons.
- Home cards now blend into the backdrop (structure via content, not fills) — intentional pure-black look; on-surface text stays #f2f0f8 (18.6:1).
- Keep private-mode violet: changing icon_color_accent_violet would erase the privacy-mode visual distinction.
- Rule for future theme work: token remap > layout surgery; hairlines are the only cheap structure on AMOLED.
