# Design System Strategy: SHADOW RUN

## 1. Overview & Creative North Star
**Creative North Star: "The Relentless Pulse"**

This design system moves away from the "cheap jump-scare" aesthetic of typical horror apps and leans into **Sophisticated Dread**. We are building a high-end, editorial experience that feels intimidating yet impeccably clean. The layout breaks the traditional rigid mobile grid by utilizing intentional asymmetry—heavy-weighted headers on one side balanced by thin, precise data points on the other. 

To achieve a "signature" feel, we avoid standard templates in favor of **Tonal Brutalism**. The interface should feel like a redacted military document or a high-end sports car dashboard at midnight. We use extreme contrast to create focus, treating every screen as a composition rather than a container for data.

---

## 2. Colors
The palette is rooted in absolute darkness, using red not as a decoration, but as a warning and a pulse.

### The Palette (Material Design Mapping)
*   **Background (Pure Void):** `#131313` (mapped to `surface` and `background`)
*   **Primary (The Pulse):** `#ffb3b4` (mapped to `primary`) / `#ff5262` (mapped to `primary_container`)
*   **Secondary (The Shadow):** `#920223` (mapped to `secondary_container`)
*   **Tertiary (The Ghost):** `#6bd9c7` (mapped to `tertiary`) — *Use sparingly for "safe" zones or completed milestones.*

### The "No-Line" Rule
**Explicit Instruction:** Prohibition of 1px solid borders for sectioning. 
Boundaries must be defined solely through background color shifts. To separate a run card from the activity feed, use `surface_container_low` against the `background`. If a section needs emphasis, use `surface_bright`. Structural lines are a sign of weak hierarchy; use the "void" (spacing) to define edges.

### Surface Hierarchy & Nesting
Treat the UI as layered sheets of obsidian. 
1.  **Base Layer:** `surface` (#131313) - The infinite path.
2.  **Sectional Layer:** `surface_container_low` (#1c1b1b) - Used for broad groupings.
3.  **Actionable Cards:** `surface_container_highest` (#353534) - To bring critical stats "closer" to the user.

### Signature Textures: The "Bleed"
To add professional polish, primary CTAs should not be flat hex codes. Use a subtle linear gradient from `primary` to `primary_container` (Top-Left to Bottom-Right). This creates a "glow" effect that mimics a light source in the dark, giving the button a tactile, urgent soul.

---

## 3. Typography
The typography system relies on the tension between the aggressive, industrial **Space Grotesk** and the invisible precision of **Inter**.

*   **Display & Headlines (The Voice):** Use `display-lg` through `headline-sm` with **Space Grotesk**. This should be tracked tightly (-2% to -4%) to feel compressed and high-pressure.
*   **Body & Stats (The Intel):** Use `body-md` and `label-md` with **Inter**. For running stats (BPM, Pace), use `title-lg` in Inter with tabular lining to ensure numbers don't jump during active tracking.
*   **Hierarchy Note:** High-contrast scale is mandatory. A `display-lg` headline should often sit directly next to a `label-sm` metadata tag to create a sense of scale and importance.

---

## 4. Elevation & Depth
In a horror-themed app, traditional shadows feel too "friendly." We use **Tonal Layering** and **Atmospheric Perspective**.

*   **The Layering Principle:** Depth is achieved by "stacking." Place a `surface_container_lowest` card inside a `surface_container_high` area to create a "recessed" or "carved" look. 
*   **Ambient Shadows:** For floating elements (e.g., a "Stop Run" FAB), use a hyper-diffused shadow: `Y: 20px, Blur: 40px, Color: #000000 at 40%`. It should feel like a weight on the screen, not a light lift.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline_variant` at 15% opacity. It should be barely perceptible—a "whisper" of a boundary.
*   **Glassmorphism (The Fog):** Overlays (Modals/Popups) must use `surface_container_low` at 80% opacity with a `20px` backdrop blur. This allows the red "pulse" of the run tracking to bleed through the dark fog of the menu.

---

## 5. Components

### Buttons
*   **Primary (The Action):** Filled with the "Bleed" gradient (`primary` to `primary_container`). Radius: `full`. Text: `label-md` All-Caps.
*   **Secondary (The Choice):** Ghost style. No fill, `outline_variant` at 20% opacity. Text: `on_surface`.
*   **Tertiary (The Ghost):** Text only, `primary` color, no background.

### Cards & Lists
*   **Rule:** Forbid divider lines.
*   **Structure:** Use `xl` (1.5rem) rounded corners for cards to soften the brutalism and make the app feel "modern-tech." 
*   **Spacing:** Use massive vertical padding (32px+) to allow the typography to breathe. Content should feel like it's floating in the dark.

### Critical Components for SHADOW RUN
*   **The Pulse Tracker:** A custom component using `primary` with a high-glow `surface_tint`. No container—just raw data against the void.
*   **The Warning Banner:** Uses `error_container` with a `20%` opacity background and `on_error_container` text. It should feel like a system alert.
*   **Selection Chips:** Use `sm` (0.25rem) rounded corners. Unselected: `surface_container_high`. Selected: `primary` with `on_primary` text.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use asymmetrical margins (e.g., 24px left, 40px right) to create a sense of unease and movement.
*   **Do** use `spaceGrotesk` for all numerical data related to "threats" or "speed."
*   **Do** lean into "Pure Black" (`#0A0A0A`) for the furthest background depths.

### Don't:
*   **Don't** use 100% white text. Use `on_surface` (#e5e2e1) to prevent eye strain in dark environments.
*   **Don't** use standard material "Drop Shadows." They break the flat, modern horror aesthetic.
*   **Don't** use rounded corners on every element. Keep buttons "pill" shaped, but keep containers subtly rounded (`md` or `lg`) to maintain an industrial edge.
*   **Don't** use icons with fills. Use thin-stroke (1.5px) linear icons to maintain the "clean/minimal" requirement.

---
**Director's Note:** Remember, this system is about the *absence* of light. Every element you add should feel like it was fought for. If a component doesn't serve the "Relentless Pulse" of the runner, kill it.