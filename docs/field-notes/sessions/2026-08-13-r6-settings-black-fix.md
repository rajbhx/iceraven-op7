# Session digest — 2026-08-13 — r6 settings black-void fix (AMOLED)

## Problems solved
- **P** after r5 AMOLED patch, the browser Settings page rendered as a pure-black void ("Only browser settings page black")
  cause: androidx.preference rows are transparent ripples over the activity colorBackground (fx_mobile_background = #000000) and its list divider is #1f000000 (invisible on black); no container token reaches the rows, so raising container_low/lowest alone would NOT fix the main settings list
  solution: r6 gives preference rows a real card surface — new @layout/op7_preference_row (derived from androidx preference_material 1.2.1, inset 12dp card, rounded 12dp, fill ?attr/colorSurfaceContainer = #1A1A1A = home-card tone) wired via PreferenceTheme.preferenceStyle + SwitchCompatPreferenceMaterialStyle; androidx list dividers neutralized (transparent) so full-width lines don't cross card gaps; container scale lifted off pure black (lowest #0A0A0A < low #121212 < container #1A1A1A < high #1F1F1F < highest #242424) so Compose sub-screens using colorSurfaceContainer* stay visible; background/surface/dim stay true black
  section: F
  tags: amoled, settings, preferences, theme, colors, resource-only, r6
- **P** handoff theory ("settings rows sit on container_low/lowest") was wrong for the main list
  cause: Preference styleable has no android:background; preference_material.xml root uses only selectableItemBackground ripple; PreferenceFragmentCompat draws rows over colorBackground with a #1f000000 divider
  solution: verified against androidx.preference 1.2.1 AAR (preference-1.2.1.aar) + upstream fenix styles.xml before patching; fixed the actual structure carriers (row surface + dividers) instead of only tokens
  section: E
  tags: root-cause, androidx, resources
- **P** regenerating patch 005 needed real upstream blob hashes
  cause: r5 patch's index lines were hand-assembled (before-hash d74cdcb ≠ upstream blob cee5b72)
  solution: rebuilt 005 from pristine upstream files in a scratch git repo so index lines are true content hashes; verified git apply --check on fresh baseline and after 004; result files byte-identical to intended state
  section: E
  tags: patch, git-apply, generation

## Notes
- Verified androidx.preference 1.2.1: `PreferenceThemeOverlay.v14.Material` is empty; real styles live in `BasePreferenceThemeOverlay`; `PreferenceFragmentCompat$DividerDecoration` applies the fragment `android:divider`.
- r6 keeps the AMOLED win where it matters: background/surface/dim stay #000000 (chrome + page backdrop); only content-bearing surfaces are lifted.
- Rows covered: plain Preference + SwitchPreferenceCompat (the two that dominate preferences.xml). Custom Fenix rows (sign-in, account, ETP checkboxes) keep their own layouts/backgrounds; their text/widgets stay readable.
- On-device screenshot QA of Settings was not possible this session (assistant overlay focus race); CI compile + user visual check is the gate.
