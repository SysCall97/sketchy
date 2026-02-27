# Design Guidelines — SwiftUI

## 1. Design Principles

- Minimal UI
- No visual clutter
- Focus on drawing area
- Large touch targets
- Single-responsibility controls

---

## 2. Color & Background

### Above Paper Mode
- Camera feed as background
- No additional background layers

### Under Paper Mode
- Solid white background only
- No gradients
- No textures

---

## 3. Controls & Interaction

### Mode Switch
- Always visible
- Clear text or icon + label
- Positioned consistently across modes

### Sliders
- Horizontal sliders
- Large thumb for precision
- Labels:
  - Opacity
  - Brightness

### Transform Controls
- One parent button:
  - Opens transform mode selector
- Sub-options:
  - Template
  - Camera (Above mode only)

---

## 4. Template Bounding Box

- Visible border
- Semi-transparent handles or corners
- Gestures:
  - Drag → move
  - Pinch → scale
- No rotation in MVP

---

## 5. SwiftUI Layout Rules

- Use `ZStack` for:
  - Camera layer
  - Template layer
  - UI controls
- Keep controls outside drawing area when possible
- Use `GeometryReader` for scaling consistency
- Avoid deeply nested views

---

## 6. Typography & Icons

- System font only
- SF Symbols preferred
- No custom fonts in MVP

---

## 7. Accessibility & Safety

- Disable auto-lock during drawing
- Warn user if brightness is high (future)
- Support light mode only (dark mode optional later)

---

## 8. Animations

- Minimal
- Only for mode switching or control appearance
- No animated templates
