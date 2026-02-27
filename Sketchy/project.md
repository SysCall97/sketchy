# Project Architecture — MVVM-C

## 1. Architecture Overview

The app follows MVVM-C:
- Model: Data and state
- View: SwiftUI views
- ViewModel: Business logic
- Coordinator: Navigation and flow control

---

## 2. High-Level Modules

- AppCoordinator
- HomeModule
- DrawingModule
- TemplateModule
- CameraModule
- RenderingModule (Metal)

---

## 3. Coordinators

### AppCoordinator
- App launch
- Root navigation
- Mode switching flow

### DrawingCoordinator
- Handles:
  - Enter drawing screen
  - Switch between drawing modes
  - Exit drawing screen

---

## 4. Views (SwiftUI)

- HomeView
- TemplateGalleryView
- DrawingView
- ModeSwitchView
- ControlPanelView

Views contain:
- No business logic
- Only bindings to ViewModels

---

## 5. ViewModels

### DrawingViewModel
Responsibilities:
- Current mode (Above / Under)
- Template transform state
- Opacity values
- Brightness value
- Flashlight state
- Camera transform state

### TemplateViewModel
Responsibilities:
- Load template image
- Provide image metadata

---

## 6. Models

- TemplateModel
  - id
  - imageURL / imageName
- DrawingState
  - mode
  - templateTransform
  - cameraTransform
  - opacity
  - brightness

---

## 7. Services / Managers

- CameraService
  - AVFoundation wrapper
- FlashlightService
- BrightnessService
- MetalRenderer
  - Handles:
    - Camera texture
    - Template texture
    - Opacity shader

---

## 8. Data Flow

SwiftUI View  
→ ViewModel  
→ Service / Renderer  
→ State Update  
→ View Refresh

No direct View → Service calls.

---

## 9. Testing Strategy

- Unit tests:
  - ViewModels
  - Transform logic
- Manual testing:
  - Camera overlay
  - Lightbox mode
  - Mode switching
