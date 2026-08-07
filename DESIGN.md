---
name: PTE-100 Public Website
description: A technical proof sheet for clearer Portuguese documentation.
colors:
  ink: "#101820"
  orange: "#f26b38"
  orange-deep: "#c64c20"
  lime: "#b9e66b"
  paper: "#f2f4f3"
  paper-deep: "#e3e8e7"
  paper-line: "#c8d0cf"
  white: "#fbfcfb"
typography:
  display:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "clamp(3.5rem, 6.3vw, 6.25rem)"
    fontWeight: 600
    lineHeight: 0.96
    letterSpacing: "-0.065em"
  headline:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "clamp(2.6rem, 5vw, 5.2rem)"
    fontWeight: 600
    lineHeight: 0.98
    letterSpacing: "-0.06em"
  body:
    fontFamily: "Manrope, Helvetica Neue, Arial, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "DM Mono, Courier New, monospace"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "0.12em"
rounded:
  none: "0px"
  circle: "50%"
spacing:
  shell: "min(1180px, calc(100% - 64px))"
  section: "132px"
  compact: "22px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    rounded: "{rounded.none}"
    padding: "0 19px"
    height: "48px"
  button-light:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "0 19px"
    height: "48px"
  proof-sheet:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "0"
---

# Design System: PTE-100 Public Website

## Overview

**Creative North Star: "A technical proof sheet"**

The landing page treats controlled language as an editorial engineering practice. It borrows the visual discipline of a marked-up proof: cool paper, dark ink, measurement lines, small machine labels, and orange interventions that show where meaning becomes more precise. The tone is direct and open, not corporate and not an AI product dashboard.

The page moves from a concrete before/after example to the rule system, then to the offline linter and the public repository. The signature is the proof sheet itself: the page demonstrates its claim before explaining it. Flat surfaces carry most of the experience; a few hard-edged shadows make the proof sheet and terminal feel like physical working artifacts.

**Key Characteristics:**
- Cool paper and ink, with orange corrections and lime validation states.
- Serif display voice paired with sans-serif reading text and mono annotations.
- Horizontal rules, measurement marks, and zero-radius rectangular forms.
- The repository remains the canonical source; the website is an entry point.

## Colors

The palette is a cool working surface with two functional signals: orange marks an editorial intervention, while lime confirms a valid or active state.

### Primary
- **Ink Navy** (#101820): Primary text, navigation, terminal, and structural lines.
- **Revision Orange** (#f26b38): Corrections, status marks, focus, and high-attention actions.
- **Revision Orange Deep** (#c64c20): Text-safe orange for headings, labels, and links.

### Secondary
- **Validation Lime** (#b9e66b): Positive state, highlighted terms, and dark-section accents.

### Neutral
- **Cool Paper** (#f2f4f3): Main page ground and light button surface.
- **Paper Deep** (#e3e8e7): Secondary tonal surface.
- **Paper Line** (#c8d0cf): Quiet grid and divider lines.
- **Proof White** (#fbfcfb): The raised proof-sheet surface.

### Named Rules
**The Mark Means Something Rule.** Orange and lime are functional signals, not decorative sprinkles: orange intervenes, lime validates.

## Typography

**Display Font:** Georgia (with Times New Roman fallback)
**Body Font:** Manrope (with Helvetica Neue and Arial fallbacks)
**Label/Mono Font:** DM Mono (with Courier New fallback)

**Character:** Display text feels editorial and deliberate; body text is neutral and highly readable; mono labels make status, rule IDs, and measurements feel inspectable.

### Hierarchy
- **Display** (600, `clamp(3.5rem, 6.3vw, 6.25rem)`, `.96): Hero thesis and closing statement.
- **Headline** (600, `clamp(2.6rem, 5vw, 5.2rem)`, `.98): Section statements and product ideas.
- **Title** (700, 20px, 1.2): Level and component names.
- **Body** (400, 16px, 1.55): Explanatory copy; keep measures around 65–75ch where possible.
- **Label** (500, 11px, 1.2, tracked uppercase): Status, provenance, rule ranges, and section markers.

### Named Rules
**The Copy Is the Interface Rule.** Headlines carry the point of view; labels provide coordinates and never replace the message.

## Layout

The page uses a centered shell of roughly 1180px with 32px side gutters on narrow screens. Desktop sections alternate between split compositions and full-width rails rather than a repeated card grid. The first viewport is a two-column proof: editorial thesis on the left and the marked-up demonstration sheet on the right.

Sections use generous vertical spacing, usually around 120–165px, while dense artifacts use compact 14–20px internal rules. On smaller screens, columns become a single reading order, the proof sheet loses its rotation, and the levels rail becomes a vertical sequence. Navigation collapses to the wordmark and GitHub action.

## Elevation & Depth

The system is mostly flat and structural. Depth comes from borders, paper tonal shifts, and one deliberately physical offset shadow: the proof sheet uses a 10px navy shadow on desktop and 8px on mobile; the terminal uses a softer transparent offset. Avoid ambient glow and glass effects.

### Shadow Vocabulary
- **Proof offset** (`10px 10px 0 #101820`): Makes the before/after sheet feel like a working document placed on the page.
- **Terminal offset** (`18px 18px 0 rgba(16,24,32,.24)`): Separates the diagnostic artifact from the orange field.

## Shapes

Forms are rectangular and intentional. Buttons, rules, terminal chrome, and sheets use zero-radius corners. The only rounded form is the small circular status dot and terminal lights. Borders are predominantly 1px ink or paper-line strokes; the orange correction line is 2px.

## Components

### Buttons
- **Shape:** Square and compact, with no radius (0px).
- **Primary:** Ink navy background, cool-paper text, mono label, 48px height, 19px horizontal padding.
- **Hover / Focus:** Rises 3px on hover and changes to deep orange; keyboard focus uses a 3px orange outline with 5px offset.
- **Light:** Cool-paper background on orange sections; hover changes to validation lime.

### Cards / Containers
- **Proof sheet:** White paper, 1px ink border, structured header/footer, lined writing surface, and a hard navy offset shadow.
- **Terminal:** Ink navy rectangle with a thin chrome bar, three status lights, and mono diagnostic output.
- **Rule rows:** Border-bottom list items rather than cards; hover translates the row 8px and adds a faint orange field.

### Navigation
- **Style:** Small, bold sans-serif links with a compact rectangular GitHub action.
- **States:** Links shift to deep orange on hover; the GitHub action remains a high-contrast ink block.
- **Mobile:** Secondary anchors hide; the GitHub action remains available beside the wordmark.

### Signature Component
- **Annotated proof sheet:** The first viewport's core demonstration. It pairs a crossed-out ambiguous sentence with a numbered, explicit revision and rule IDs. Keep the before/after relationship legible without relying on the orange strike line alone.

## Do's and Don'ts

### Do:
- **Do** show the PTE-100 mechanism through a real before/after example before making abstract claims.
- **Do** use the orange and lime accents as meaningful editorial states.
- **Do** keep links and CTAs pointed at the canonical `forge-z/pte100` repository.
- **Do** preserve the experimental status of v0.1 in public-facing copy.
- **Do** maintain keyboard focus, readable contrast, and reduced-motion behavior.

### Don't:
- **Don't** introduce customer logos, testimonials, benchmarks, certification, or adoption claims without evidence.
- **Don't** turn the landing page into a second source of normative rules.
- **Don't** replace the proof-sheet composition with a generic hero-plus-icon-card layout.
- **Don't** use gradients, glass effects, or decorative glow as substitutes for content.
