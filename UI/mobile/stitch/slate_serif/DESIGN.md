```markdown
# Design System Strategy: The Digital Atelier

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Editorial Sanctuary."** 

RSS readers are often cluttered, utility-driven technical interfaces. This system rejects that paradigm, instead treating digital content with the reverence of a high-end, bespoke printed journal. We move beyond "minimalism" into "intentionalism"—where every pixel of white space is a deliberate choice to reduce cognitive load. 

The system breaks the "template" look by utilizing **The Asymmetric Anchor**: avoiding perfectly centered grids in favor of wide margins and staggered content starts. This creates a rhythm that feels human, curated, and premium.

---

## 2. Colors & Tonal Depth
Our palette transitions from the warmth of a physical library (Cream) to the focused depth of a midnight study (Deep Slate).

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts. 
- Separation is achieved by placing a `surface-container-low` component against a `surface` background. 
- This creates a sophisticated, "molded" look rather than a "boxed" look.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers of fine paper. 
- **Base:** `surface` (#f9f9f7)
- **Secondary Sections:** `surface-container-low` (#f4f4f2)
- **Elevated Content/Cards:** `surface-container-lowest` (#ffffff)
- **High-Focus Interaction:** `surface-container-high` (#e8e8e6)

### The "Glass & Gradient" Rule
To prevent a flat, "web-1.0" feel, use **Glassmorphism** for navigation overlays and floating action bars. 
- Use `surface` at 80% opacity with a `24px` backdrop-blur. 
- **Signature Textures:** For primary CTAs, use a subtle linear gradient from `primary` (#00497d) to `primary_container` (#0061a4) at a 135-degree angle. This adds "soul" and a tactile, liquid quality to the primary blue accent.

---

## 3. Typography: The Editorial Voice
Typography is the core of this system. We pair the precision of **Inter** for utility with the literary heritage of **Newsreader** (interpreting the Lora/Merriweather request for a more bespoke editorial feel).

- **The Display Scale:** Used for article titles and category headers. `display-lg` (3.5rem) should be set with tight letter-spacing (-0.02em) to feel like a masthead.
- **The Reading Experience:** `body-lg` (Newsreader, 1rem) is the heartbeat of the system. It must maintain a line-height of 1.6 to ensure maximum legibility during long-form reading sessions.
- **Utility & Metadata:** All UI labels, timestamps, and "source" tags use **Inter** (`label-md`). This creates a clear distinction between the "System" (Inter) and the "Story" (Newsreader).

---

## 4. Elevation & Depth: Tonal Layering
We do not use shadows to imply "standard" height; we use them to imply "ambience."

- **The Layering Principle:** Depth is achieved by stacking. Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift without a shadow.
- **Ambient Shadows:** When a floating effect is required (e.g., a "New Posts" toast), use an extra-diffused shadow: `box-shadow: 0 12px 40px rgba(26, 28, 27, 0.06);`. The shadow color must be a tinted version of `on-surface`, never pure black.
- **The "Ghost Border" Fallback:** If accessibility requires a container edge, use a "Ghost Border": `outline-variant` (#c1c7d2) at **15% opacity**.
- **Glassmorphism:** Navigation rails should use semi-transparent `surface` colors to allow article imagery to bleed through softly, making the layout feel integrated.

---

## 5. Components

### Buttons
- **Primary:** Rounded (`full`), using the signature blue gradient. Typography: `label-md` (Inter), Uppercase, 0.05em tracking.
- **Tertiary (Ghost):** No container. Use `on-surface-variant` for text. On hover, transition to a `surface-container-high` background pill.

### Cards & Feed Lists
- **The Rule of Zero Dividers:** Forbid the use of horizontal divider lines. Use `1.5rem` to `2rem` of vertical white space to separate feed items.
- **The "Hero" Card:** Uses `surface-container-lowest` with a `lg` (1rem) corner radius and a subtle 4% ambient shadow.

### Reading Progress Indicator
A custom component: a 2px stroke at the top of the viewport using `primary` blue, transitioning into `surface-tint` as the user scrolls.

### Interaction Chips
- Use `surface-container-highest` for unselected states and `primary` with `on-primary` text for active filters. Radius: `sm` (0.25rem) for a more "architectural" feel.

---

## 6. Do's and Don'ts

### Do:
- **Do** use "Optical Centering." Sometimes a headline looks better slightly offset to the left to align with the vertical stem of a serif capital letter.
- **Do** lean into `surface-dim` for "Dark Mode" transitions to avoid pure black (#000), which causes eye strain during reading.
- **Do** use `tertiary` (#713700) for "Save for Later" or "Bookmark" actions to provide a warm, haptic-like contrast to the Primary Blue.

### Don't:
- **Don't** use 100% opaque borders. They "trap" the content and break the editorial flow.
- **Don't** use Inter for article content. Inter is for "navigating"; Newsreader is for "absorbing."
- **Don't** crowd the margins. In the reading view, the gutter should be at least 15% of the total screen width on each side to mimic the margins of a physical book.
- **Don't** use standard "drop shadows" with high opacity. If the shadow is noticeable at first glance, it is too heavy.