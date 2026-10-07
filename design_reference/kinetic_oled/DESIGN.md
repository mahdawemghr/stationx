---
name: Kinetic OLED
colors:
  surface: '#131316'
  surface-dim: '#131316'
  surface-bright: '#39393c'
  surface-container-lowest: '#0e0e11'
  surface-container-low: '#1b1b1e'
  surface-container: '#1f1f22'
  surface-container-high: '#2a2a2d'
  surface-container-highest: '#353438'
  on-surface: '#e4e1e6'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e4e1e6'
  inverse-on-surface: '#303033'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#ddb7ff'
  on-secondary: '#490080'
  secondary-container: '#6f00be'
  on-secondary-container: '#d6a9ff'
  tertiary: '#d8ffe7'
  on-tertiary: '#003824'
  tertiary-container: '#65f2b5'
  on-tertiary-container: '#006d4a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#f0dbff'
  secondary-fixed-dim: '#ddb7ff'
  on-secondary-fixed: '#2c0051'
  on-secondary-fixed-variant: '#6900b3'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#131316'
  on-background: '#e4e1e6'
  surface-variant: '#353438'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-numeric:
    fontFamily: JetBrains Mono
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
  label-numeric-sm:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
  label-xs:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The brand personality is precise, relentless, and high-performance. Tailored for dedicated athletes and analytical fitness enthusiasts who train with intent, the interface treats workout tracking as telemetry rather than passive logging. The emotional tone avoids cheerful gamification in favor of an empowering, high-contrast, performance-lab instrument feel.

The design fuses **Minimalism** with an **OLED-first High-Contrast** aesthetic:
- **True Black Infinity Canvas:** Pure `#000000` grounds the viewport, maximizing battery efficiency on mobile OLED displays while creating deep negative space.
- **Instrument Precision:** Surfaces sit as calibrated dark slate tiles bordered by ultra-thin hairline dividers. Interactive states ignite in razor-sharp neon cyan and electric violet.
- **Ergonomic Focus:** Critical touch targets and data interactions live within the bottom 60% of the screen (the "thumb zone"), minimizing reach during intense training sessions.

## Colors

The palette operates under a high-contrast dark discipline, relying on luminous spectral accents over deep low-reflectance foundations.

### Accent Roles
- **Primary (`#00F0FF` - Electric Cyan):** Primary CTAs, active stopwatch/timer readouts, current set highlights, and linear progress telemetry. Radiates sharp clarity against pitch-black backgrounds.
- **Secondary (`#A855F7` - Neon Violet):** Secondary CTAs, volume loads, split analytics, and comparative personal record (PR) indicators. Pairs with Cyan in gradients for high-value milestone charts.
- **Tertiary (`#10B981` - Kinetic Emerald):** Instant validation, completed set checkmarks, target heart rate zones, and positive delta gains.
- **Destructive / Alert (`#EF4444` - Crimson Flame):** Failed sets, dropped intensity alerts, deletion states, and critical rest-timer overruns.

### Surface System
- **Background (`#000000`):** Pure OLED black for root scaffolds and root bottom sheets.
- **Surface Tier 1 (`#121212`):** Primary structural cards, group containers, and base list segments.
- **Surface Tier 2 (`#18181B`):** Elevated components, interactive input wells, and active modal sheets.
- **Surface Tier 3 (`#27272A`):** Toggled state backgrounds, chips, and segment controllers.
- **Border Hairline (`#27272A`):** 1px structural separator across cards and inputs.
- **Text & Foreground:** `#FFFFFF` (Headings, primary values), `#A1A1AA` (Labels, inactive tab items), and `#52525B` (Muted hints, metadata stamps).

## Typography

The type hierarchy balances athletic display energy with clinical readability.

- **Headlines (`Space Grotesk`):** Delivers a technical, sharp demeanor for workout names, high-level summaries, and milestone celebrations. Tracking is tightly set (`-0.02em`) to maintain density.
- **Body & Controls (`Inter`):** Offers neutral, utilitarian legibility for exercise instructions, settings, notes, and general UI labels.
- **Telemetry & Numbers (`JetBrains Mono`):** Dedicated exclusively to reps, load weights, rest countdowns, and performance charts. Monospaced tabular alignment ensures numbers never jitter or shift layout during live countup/countdown states.

All body copy defaults to `#A1A1AA` for reduced eye fatigue in dim gym conditions, reserving pure `#FFFFFF` for primary numeric readouts and active titles.

## Layout & Spacing

The layout is built around a mobile-first fluid single-column structure, transitioning into a multi-column modular grid for tablets and foldables.

### Rhythm & Density
- **Base Grid Unit:** Strictly 4px/8px modular rhythm. Component paddings rely on `space-sm` (8px) and `space-md` (16px) to maximize available telemetry data per viewport inch without visual clutter.
- **Canvas Margins:** Fixed 16px (`1rem`) lateral margins ensure cards don't touch display bezels, with safe-area insets handled gracefully on notched and edge-to-edge mobile devices.
- **Workout Active Flow:** Data entry forms (Set, Weight, Reps, RPE) use compact vertical stacking (`space-xs` to `space-sm`) to ensure the on-screen numeric keypad never obscures the active input row.

### Breakpoints & Adaptive Rules
- **Compact (<600px - Mobile):** Full-bleed true black canvas, vertical single-column card stacking, sticky bottom actions, and fixed bottom navigation bar (64px + safe area).
- **Medium (600px - 840px - Foldables / Small Tablets):** 2-column split view (Routine overview on the left 40%, active set logging and telemetry on the right 60%).
- **Expanded (>840px - Large Tablets):** Centered max-width shell of 720px for singular focused workouts, or 3-column analytics views with persistent navigation rail.

## Elevation & Depth

To protect OLED power-savings and maintain sleek modern dark ergonomics, this design system rejects heavy drop shadows. Depth is achieved entirely through **Tonal Stacking** and **Subtle Hairline Borders**.

- **Level 0 (Canvas Base):** Pure `#000000`. Houses main views, background charts, and inactive regions.
- **Level 1 (Card & Module Shells):** `#121212` with a continuous `1px solid #27272A` outline. Used for exercise containers, routine cards, and dashboard tiles.
- **Level 2 (Active/Pressed States & Inner Wells):** `#18181B` with `1px solid #3F3F46`. Applied to weight/rep input fields, selected chips, and swipeable workout log rows.
- **Level 3 (Modals, Overlays, and Sheets):** `#18181B` with `1px solid #3F3F46` and a soft ambient glow: `0px 8px 32px rgba(0, 0, 0, 0.8)`.
- **Accent Illumination:** Interactive key elements (Floating Action Buttons, active toggles) may project an intentional, low-spread color aura: `0px 4px 20px rgba(0, 240, 255, 0.25)` or `0px 4px 20px rgba(168, 85, 247, 0.25)`.

## Shapes

The design uses a clean, contemporary curved silhouette calibrated for touch ergonomics.

- **Primary Cards and Sheets:** Standardized at `rounded-lg` (16px / 1rem). This rounds workout blocks comfortably without sacrificing tabular data density inside card corners.
- **Action Buttons & Inputs:** Form elements, set log fields, and secondary CTA pills carry `rounded` (8px / 0.5rem) to ensure crisp spatial boundaries.
- **Chips, Badges, and FABs:** Fully circular or capsule-shaped (`9999px` / pill) to differentiate actionable meta-tags and primary navigation triggers from structural data containers.

## Components

### Buttons & Interactive CTAs
- **Primary CTA:** Solid Electric Cyan (`#00F0FF`) background with high-contrast `#000000` bold typography. Height 52px, pill-curved (`rounded-full`), with subtle cyan glow on press.
- **Secondary CTA:** Deep surface (`#18181B`) background with a 1px border of `#A855F7` (Neon Violet) and `#FFFFFF` text.
- **Floating Action Button (FAB):** 56x56px circular action anchored 16px above the bottom navigation bar. Features an Electric Cyan to Neon Violet subtle linear gradient (`45deg, #00F0FF, #A855F7`) with pure black icon.

### Cards & Workout Logging Tables
- **Exercise Card:** Encased in `#121212`, 16px corner radius, hairline `#27272A` border. Contains exercise header, equipment tag, and collapsible telemetry table.
- **Set Row (Tabular Entry):** Compact 40px height row. Set number styled in `JetBrains Mono` muted gray (`#71717A`). Weight and Rep fields appear as dark input insets (`#18181B`) with monospaced white figures.
- **Completion Checkbox:** 28x28px squircle (`rounded-md`). Inactive state is transparent with 1.5px `#3F3F46` border; complete state transitions immediately to `#10B981` (Kinetic Emerald) fill with a bold white check.

### Input Fields
- **Data Inset Boxes (Weight/Reps):** Grounded in `#18181B` with 1px `#27272A` border and `8px` corner radius. Numeric text is centered, bold `JetBrains Mono`. Active/focused field transitions border to `#00F0FF` with a hairline 1px ring.

### Progress Rings & Charts
- **Circular Progress (Rings):** Unfilled track sits at `#18181B` with 6px stroke width. Active progress rendered in continuous `#00F0FF` or `#A855F7` with rounded stroke caps.
- **Telemetry Charts:** Line charts utilize a `#00F0FF` 2px vector path atop a faint vertical gradient fade (`rgba(0, 240, 255, 0.12)` down to `transparent`). Gridlines are ultra-muted at `#27272A`.

### Navigation & Bottom Ergonomics
- **Bottom Navigation Bar:** Fixed at the base with safe-area insets. Surface set to `#0C0C0E` with 1px top border `#27272A`. Inactive items rendered in `#71717A`; selected state lights up with `#00F0FF` icon and a miniature 3px cyan indicator dot below.
- **Rest Timer Drawer:** Persistent, non-intrusive 48px sticky banner above bottom navigation that animates into view upon set checkoff, showing a live monospaced countdown with an Electric Cyan progress bar.