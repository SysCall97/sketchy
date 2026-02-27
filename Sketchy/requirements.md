# Drawing Template App — Requirements

## 1. Project Scope (MVP)

The app allows users to trace drawing templates using two modes:
1. Device placed above the paper (camera overlay mode)
2. Device placed under the paper (lightbox mode)

Out of scope for MVP:
- AR / ARKit
- Drawing tutorials
- Step-by-step guides
- Perspective correction
- Social features

---

## 2. Template Assets

- Templates can be any image format:
  - PNG
  - JPG
  - WEBP
- Transparency is optional
- Templates are rendered as reference images only
- No requirement for SVG or vector format
- One template image per drawing session

---

## 3. Global Drawing Screen Requirements

Applies to **both modes**.

### Mandatory UI Elements
1. Mode switch button:
   - Above Paper
   - Under Paper
2. Template bounding box:
   - Can be moved (drag)
   - Can be scaled (pinch)
   - Visible border or handles

---

## 4. Drawing Modes

### 4.1 Above Paper Mode (Camera Overlay)

#### Core Behavior
- Camera: ON
- Live camera feed visible
- Template rendered on top of camera feed

#### Required Controls
1. Live camera preview
2. Template bounding box
3. Opacity slider:
   - Controls template opacity
   - Range: 0%–100%
4. Transform control (single parent option):
   - Template Transform:
     - Move template
     - Scale template
   - Can be lock/unlock to indicate it's movable and scalable or not
   - Camera Transform:
     - Move camera frame
     - Scale camera frame
5. Flashlight toggle:
   - ON / OFF
   - Visible only if device supports torch

#### Notes
- No AR tracking
- No auto alignment
- Manual adjustment only

---

### 4.2 Under the Paper Mode (Lightbox)

#### Core Behavior
- Camera: OFF
- Background: solid white
- Screen acts as light source

#### Required Controls
1. Template bounding box:
   - Movable
   - Scalable
   - Can be lock/unlock to indicate it's movable and scalable or not
2. Brightness slider:
   - Increases background brightness
   - Can push screen brightness higher
3. Opacity slider:
   - Controls opacity of template reference image

#### Restrictions
- No camera permission required
- No flashlight option
- No camera transform controls

---

## 5. Mode Switching Rules

- Switching modes must:
  - Preserve template position
  - Preserve template scale
- Switching modes must reset:
  - Camera transform when leaving Above mode
  - Brightness to safe default when entering Under mode

---

## 6. Rendering & Technical Constraints

- Rendering engine: Metal
- Template opacity controlled via Metal fragment shader
- Template rendered as textured quad
- Scaling and movement handled via transform matrices
- Camera feed rendered as a separate layer

---

## 7. Device & Permissions

- Camera permission:
  - Required only for Above Paper mode
- Flashlight:
  - Optional, hardware dependent
- Prevent screen auto-lock during drawing
