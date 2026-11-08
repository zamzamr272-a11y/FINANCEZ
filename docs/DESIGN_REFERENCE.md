# Design reference adaptation

The supplied ZIP contains seven 16:9 dashboard screenshots of fleet/operations management interfaces. Common patterns observed:

- Deep charcoal/near-black canvas and layered surfaces.
- Left navigation/sidebar on desktop.
- Dense but clearly separated data panels and KPI cards.
- Amber/teal highlights, neutral typography, subtle borders, and consistent alignment.
- Tables/lists for operational records, plus chart/map modules.

NEXORA translates those patterns to personal finance and community rather than copying the source product's logo, fleet content, or brand identity.

## NEXORA tokens

- Dark canvas: `#0B1117`
- Dark surfaces: `#111B24`, `#17232E`
- Main text: `#F3F6F8`
- Secondary text: `#9AA8B4`
- Teal: `#42D6C5`
- Amber: `#F2B35E`
- Income/positive: `#39C98A`
- Expense/risk: `#F16D72`
- Light canvas: `#F4F7F8`
- Light cards: `#FFFFFF`
- Light text: `#15212B`

The responsive web layout uses a sidebar and multi-column panels; mobile uses one-column cards and five-item bottom navigation. The frontend bundles Inter (SIL OFL 1.1, subset Latin, weights 400/500/600/700 in `frontend/assets/fonts/`) as its single typeface for all text, numbers, and chart labels, so it looks identical on every device and works offline. Type scale: 12 / 13 / 14 / 16 / 20 / 24 / 28 px; nothing below 12px. A lightweight original SVG mascot is included as a static asset; a full 3D animated mascot is not yet implemented.
