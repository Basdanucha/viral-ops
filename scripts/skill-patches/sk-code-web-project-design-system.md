# Project Design System (viral-ops)

**MANDATORY**: Read these files before writing ANY frontend code:
- `DESIGN.md` — Linear-inspired design tokens (colors, typography, spacing, components)
- `.impeccable.md` — Brand personality, audience, aesthetic direction
- `.design-pipeline.md` — Full design pipeline detail

## Non-Negotiables
- Dark-mode-native: `#08090a` background, `#0f1011` panels, `#191a1b` surfaces
- Inter Variable with `font-feature-settings: "cv01", "ss03"` on ALL text
- Weight 510 (default emphasis), 590 (strong), 400 (reading)
- Brand indigo `#5e6ad2` / `#7170ff` for CTAs only — the only chromatic color
- Semi-transparent white borders: `rgba(255,255,255,0.05)` to `rgba(255,255,255,0.08)`
- `#f7f8f8` for primary text — never pure `#ffffff`

## After Implementation
Run `/audit` — must score ≥14/20 with Anti-Patterns ≥3/4 before claiming done.
