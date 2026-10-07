---
name: Kinetic Obsidian
colors:
  surface: '#121416'
  surface-dim: '#121416'
  surface-bright: '#38393c'
  surface-container-lowest: '#0c0e10'
  surface-container-low: '#1a1c1e'
  surface-container: '#1e2022'
  surface-container-high: '#282a2c'
  surface-container-highest: '#333537'
  on-surface: '#e2e2e5'
  on-surface-variant: '#c3caad'
  inverse-surface: '#e2e2e5'
  inverse-on-surface: '#2f3133'
  outline: '#8d947a'
  outline-variant: '#434933'
  surface-tint: '#a5d700'
  primary: '#f4ffd3'
  on-primary: '#273500'
  primary-container: '#b8f000'
  on-primary-container: '#506a00'
  inverse-primary: '#4d6700'
  secondary: '#c2c7cd'
  on-secondary: '#2c3136'
  secondary-container: '#42474d'
  on-secondary-container: '#b1b5bc'
  tertiary: '#edffee'
  on-tertiary: '#00391d'
  tertiary-container: '#7ff5ac'
  on-tertiary-container: '#007040'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#bdf510'
  primary-fixed-dim: '#a5d700'
  on-primary-fixed: '#151f00'
  on-primary-fixed-variant: '#394d00'
  secondary-fixed: '#dee3ea'
  secondary-fixed-dim: '#c2c7cd'
  on-secondary-fixed: '#171c21'
  on-secondary-fixed-variant: '#42474d'
  tertiary-fixed: '#84fab0'
  tertiary-fixed-dim: '#67dd96'
  on-tertiary-fixed: '#00210f'
  on-tertiary-fixed-variant: '#00522d'
  background: '#121416'
  on-background: '#e2e2e5'
  surface-variant: '#333537'
typography:
  display-hero:
    fontFamily: Space Grotesk
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 60px
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  metric-xl:
    fontFamily: JetBrains Mono
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.04em
  metric-lg:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.03em
  metric-md:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.02em
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.08em
  label-ui:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system embodies high-performance athletic engineering. It serves serious lifters, strength athletes, and data-driven coaches who view progression through an analytical lens. The interface communicates surgical precision, relentless momentum, and physical durability. 

The aesthetic sits at the intersection of **Tactile Technical Minimalism** and **Industrial Precision**. Rather than generic neon fitness gamification, the visual tone mirrors high-end gym hardware, precision barbells, and calibrated laboratory instrumentation. Interfaces remain 85–90% low-luminance neutrals to preserve night-vision adaptation in dimly lit strength facilities, reserving a razor-sharp electric lime accent strictly for active states, personal records, and actionable execution cues.

## Colors

The color palette is architected for extreme visual discipline. True black and calibrated charcoal tones eliminate optical glare while providing high contrast for quick glanceability mid-set.

- **Canvas Background (`#101214`)**: Root application backdrop; provides grounding depth without harsh pure-black clipping.
- **Surface Level 1 (`#191C20`)**: Standard resting containers, workout track cards, and persistent bottom/side navigation surfaces.
- **Surface Level 2 (`#20252A`)**: Secondary utility layer; nested cells, segmented controls, set-entry rows, and active card interiors.
- **Surface Level 3 Elevated (`#252B31`)**: Floating drawers, bottom sheets, active timers, and modal dialogs.
- **Structural Dividers (`#2A3036`)**: Micro-borders and hairline dividers providing crisp spatial delineation.
- **Primary Electric Lime (`#B8F000`)**: The sole high-energy signal. Used for completion checks, PR badges, active weight plate calculations, and primary commit CTAs.
- **Tertiary Metric Green (`#7BF1A8`)**: Supportive data visualization accent denoting volume spikes and positive percentage deltas.
- **Typography Neutrals**: High-emphasis metrics use pure stark white (`#FFFFFF`), secondary body copy uses cool technical grey (`#A6B0BA`), and subdued captions utilize slate muted grey (`#606A74`).

## Typography

The typography strategy separates structural content, analytical metrics, and reading hierarchy:

1. **Space Grotesk (Headlines & Display)**: Built with mechanical geometry, sharp angles, and architectural presence. Used for routine headers, phase milestones, and exercise identities.
2. **Geist (Body & Controls)**: Neutral, neutral-density modern grotesque designed for absolute legibility in dense lists, routine notes, and coach feedback.
3. **JetBrains Mono (Metrics & Telemetry)**: Tabular monospace numbers prevent horizontal jitter when tracking rest stopwatches, weight increments, rep counts, and total calculated tonnages.

## Layout & Spacing

Layouts follow an operational, 4px-baseline modular scale tailored for single-hand touch ergonomics in high-fatigue training environments:

- **Touch Ergonomics & Margins**: Mobile workout views enforce 16px (`1rem`) exterior screen margins with large vertical targets (minimum 48px hit areas). Primary actions (Log Set, Complete Exercise) remain pinned to the thumb zone within fixed bottom viewports.
- **Grids & Columns**:
  - **Mobile (<768px)**: 4-column fluid layout with single-stacked exercise modules and inline set tables.
  - **Tablet (768px–1024px)**: 8-column grid allowing side-by-side progression charts alongside active logging forms.
  - **Desktop (>1024px)**: 12-column fixed-max layout (1280px container) supporting multi-week split planning, athlete comparison tables, and historical volume matrices.

## Elevation & Depth

Visual hierarchy is constructed through **layered surface tiers** paired with **hairline technical strokes** rather than muddy blur shadows:

- **Level 0 (Base Canvas `#101214`)**: Bottom-most foundation. Non-interactive background.
- **Level 1 (Card & Module `#191C20`)**: Elevated with a 1px solid border (`#2A3036`). No blur shadows; structure is established via explicit boundary lines.
- **Level 2 (Active Set / Cell `#20252A`)**: Recessed or stepped surfaces inside modules for individual set logging rows. Border shifts to `#2A3036` on idle, stepping to `#B8F000` (at 40% opacity) when actively being tracked.
- **Level 3 (Overlays & Pinned Dock `#252B31`)**: Modals, rest timer plates, and plate calculator sheets. Uses a subtle ambient cast: `0px 12px 32px -4px rgba(0, 0, 0, 0.7)` coupled with a top edge highlight of `1px solid rgba(255, 255, 255, 0.08)`.

## Shapes

The interface balances industrial toughness with ergonomic tactility. Radius values are standardized at 16px (`1rem`) for structural cards (`rounded-lg`), creating a clean container feel that softens the intense dark mode without compromising precision.

- **Primary Cards & Containers**: Fixed at 16px radius for harmonious, modern card framing.
- **Sub-elements & Input Fields**: Inner cells, segmented set rows, and buttons use 8px (`0.5rem`) to maintain nested geometric proportion.
- **Badges, Tags, & PR Tokens**: Fully rounded pills (`9999px`) to create an immediate shape-based contrast against structural grid modules.

## Components

### Buttons
- **Primary Action (Log Set / Finish)**: Electric Lime (`#B8F000`) solid fill with rich black (`#101214`) bold text in `Space Grotesk`. No outline. Press state compresses by 1% scale with background shifting to `#A2D400`.
- **Secondary / Utility**: Surface `#20252A` with 1px `#2A3036` border, crisp white text. Active state triggers 1px electric lime border outline.
- **Ghost Action**: Transparent background, text in cool grey (`#A6B0BA`), hover/touch brings subtle `#191C20` fill.

### Cards & Workout Modules
- Built on `#191C20` background with a 1px perimeter outline of `#2A3036` and 16px corner radius.
- Exercise cards feature a top status bar displaying current set counter (`SET 3/5`), rest timer, and previous session reference numbers in `JetBrains Mono`.

### Set Rows & Numeric Inputs
- Horizontally divided rows utilizing `#20252A` rounded containers (8px radius).
- Numeric weight and rep inputs present large `metric-md` values aligned for thumb typing. Tap target opens a dedicated custom bottom-sheet numeric keypad rather than native keyboards, preventing layout bounce.
- Set completion toggles feature an oversized square checkbox (28x28px, 6px radius) transitioning from a muted border to full `#B8F000` fill with an obsidian checkmark icon upon completion.

### Badges & Chips
- **PR / Milestone Chip**: Black fill with 1px `#B8F000` outline, text set in `#B8F000` uppercase `label-caps`. Accompanied by a geometric diamond icon.
- **RPE / Intensity Pill**: Color-coded mono pill tag (e.g., `@RPE 8.5`) in `#252B31` with `#A6B0BA` typography.

### Rest Timer Bar
- Pinned bottom horizontal component elevated on `#252B31`. Features a razor-thin 2px electric lime progress bar tracing the top border edge, accompanied by monospaced countdown digits and quick increment controls (`+30s`).