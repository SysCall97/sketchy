# Sketchy - Project Context & Design Guidelines

## Project Overview

**Sketchy** is an iOS drawing assistant app that helps users trace and draw images using two innovative modes:

1. **Draw with Camera (Above Paper)** - Overlay a reference image on live camera feed for tracing real-world objects
2. **Draw with Screen (Under Paper)** - Use the device screen as a digital lightbox with adjustable brightness

### Key Features
- Template selection from bundled assets or photo library
- Real-time camera overlay with transform controls (scale, rotation, position)
- Adjustable template opacity
- Screen brightness control for lightbox mode
- Flashlight integration for enhanced tracing
- Subscription-based access with daily usage limits
- Metal-accelerated rendering for smooth performance

---

## Technical Architecture

### Design Pattern: MVVM + Coordinator

The app follows a clean architecture combining:
- **MVVM (Model-View-ViewModel)** for UI layer
- **Coordinator Pattern** for navigation flow
- **Service Layer** for business logic and device features

```
┌─────────────────────────────────────────────────────────────┐
│                         App Layer                            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   SketchyApp │───▶│ AppCoordinator│───▶│  Navigation  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Module Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Home Module │  │Drawing Module│  │ModeSelection │     │
│  │              │  │              │  │   Module     │     │
│  │  - Views     │  │  - Views     │  │  - Views     │     │
│  │  - ViewModels│  │  - ViewModels│  │  - ViewModels│     │
│  │  - Models    │  │  - Models    │  │  - Models    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │Camera Service│  │Subscription  │  │  Rendering   │     │
│  │              │  │  Manager     │  │  (Metal)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
Sketchy/
├── SketchyApp.swift                    # App entry point, permissions
├── Coordinators/
│   ├── Coordinatable.swift            # Navigation protocol & routes
│   └── AppCoordinator.swift           # Main coordinator implementation
│
├── Modules/
│   ├── Home/                          # Template selection screen
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   ├── Models/
│   │   │   └── TemplateModel.swift
│   │   └── Utils/
│   │       └── ImageCache.swift
│   │
│   ├── ModeSelection/                 # Mode selection screen
│   │   ├── Views/
│   │   │   └── ModeSelectionView.swift
│   │   ├── ViewModels/
│   │   │   └── ModeSelectionViewModel.swift
│   │   └── Models/
│   │       └── ModeSelectionState.swift
│   │
│   ├── Drawing/                       # Main drawing interface
│   │   ├── Views/
│   │   │   ├── DrawingView.swift
│   │   │   ├── ControlPanelView.swift
│   │   │   └── TemplateBoundingBoxView.swift
│   │   ├── ViewModels/
│   │   │   └── DrawingViewModel.swift
│   │   └── Models/
│   │       └── DrawingState.swift
│   │
│   ├── Camera/                        # Camera functionality
│   │   ├── Services/
│   │   │   └── CameraService.swift
│   │   └── Views/
│   │       └── CameraPreviewView.swift
│   │
│   ├── Template/                      # Template management
│   │   └── Views/
│   │       ├── TemplateGalleryView.swift
│   │       └── PhotoPickerView.swift
│   │
│   ├── Rendering/                     # Metal rendering engine
│   │   ├── Renderers/
│   │   │   ├── MetalRenderer.swift
│   │   │   ├── CameraTextureRenderer.swift
│   │   │   └── TemplateTextureRenderer.swift
│   │   └── Models/
│   │       ├── RenderState.swift
│   │       └── Transform.swift
│   │
│   └── Paywall/                       # Subscription system
│       ├── Views/
│       │   ├── PaywallView.swift
│       │   └── DailyLimitIndicator.swift
│       └── Services/
│           └── DailyLimitManager.swift
│
├── Services/                           # Global services
│   ├── FlashlightService.swift        # Device flashlight control
│   ├── BrightnessService.swift        # Screen brightness control
│   ├── AutoLockService.swift          # Prevent screen sleep
│   ├── TransformGestureHandler.swift # Gesture recognition
│   └── KeychainManager.swift          # Secure storage
│
├── Utilities/
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── CGFloat+Extensions.swift
│   │   └── CGSize+Extensions.swift
│   └── Constants/
│       └── AppConstants.swift
│
└── Services/iAPManager/               # In-app purchases
    ├── SubscriptionManager.swift
    └── InternetChecker/
        └── InternetChecker.swift
```

---

## Key Components Explained

### 1. Navigation System (Coordinator Pattern)

**Route Definition** (`Coordinatable.swift`):
```swift
enum CoordinatorRoute: Hashable {
    case home
    case modeSelection(template: TemplateModel)
    case drawing(template: TemplateModel, mode: DrawingState.DrawingMode)
    case templateGallery
}
```

**Navigation Flow:**
```
Home → ModeSelection → Drawing
 (pick template)   (select mode)   (draw)
  ↓                      ↓               ↓
TemplateGallery ←─────────┘           (back)
(manage templates)
```

**Best Practices:**
- All navigation goes through `AppCoordinator`
- Use `coordinator.goToXxx()` methods, never direct `NavigationLink`
- Pass data via route enum associated values
- Use `coordinator.goBack()` for back navigation

### 2. Drawing Modes

#### Above Paper (Camera Overlay)
- Shows live camera feed as background
- Template overlays with adjustable opacity
- Supports camera transforms (scale, rotate, position)
- Includes flashlight toggle

#### Under Paper (Lightbox)
- White background with adjustable brightness
- Template overlays with adjustable opacity
- No camera functionality
- Simulates traditional lightbox tracing

### 3. State Management

**DrawingState** - Immutable state with builder pattern:
```swift
struct DrawingState {
    let mode: DrawingMode
    let templateTransform: Transform
    let cameraTransform: Transform
    let opacity: Double
    let brightness: Double
    let isFlashlightOn: Bool
    let transformTarget: TransformTarget
    let isTransformLocked: Bool

    func with(mode: DrawingMode? = nil, ...) -> DrawingState {
        // Returns new state with updated values
    }
}
```

**Pattern:**
- State is immutable
- Use `@Published var state: DrawingState` in ViewModels
- Update state by creating new instances via `with()` method
- Views observe state changes via `@ObservedObject`

### 4. Template System

**TemplateModel** supports three sources:
```swift
enum TemplateSource {
    case bundled(String)    // Asset catalog
    case remote(String)     // URL for async loading
    case imported(Data)     // User photos from library
}
```

**Usage:**
- Bundled templates defined in `TemplateModel.bundledTemplates`
- Remote templates loaded via `ImageCache`
- Imported photos from `PHPickerViewController`

### 5. Rendering Pipeline (Metal)

**Layers (bottom to top):**
1. **Camera Feed** or **White Background** (depending on mode)
2. **Template Image** with opacity and transforms
3. **Template Bounding Box** (when transforming)
4. **UI Controls** (back button, sliders, toggles)

**Performance:**
- Uses Metal shaders for efficient rendering
- GPU-accelerated transforms
- 60fps target frame rate

---

## Coding Conventions

### SwiftUI View Structure

**Standard Template:**
```swift
/// Brief description of what this view does
struct FeatureView: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel: FeatureViewModel

    // MARK: - State
    @State private var localState: Type = defaultValue

    // MARK: - Initializer
    init(coordinator: AppCoordinator, dependency: Type) {
        self.coordinator = coordinator
        self._viewModel = StateObject(
            wrappedValue: FeatureViewModel(dependency: dependency)
        )
    }

    // MARK: - Body
    var body: some View {
        // UI implementation
    }
}

// MARK: - Private Components

private struct SubComponent: View {
    // Helper views
}
```

### ViewModel Pattern

**Standard Template:**
```swift
@MainActor
class FeatureViewModel: ObservableObject {
    @Published var state: FeatureState

    // MARK: - Services
    private let service: SomeService

    // MARK: - Initializer
    init(dependency: Type) {
        // Initialize state
        self.state = FeatureState.initial
        self.service = SomeService()
    }

    // MARK: - Actions
    func performAction() {
        // Update state
        state = state.with(property: newValue)
    }
}
```

**Guidelines:**
- Always mark `@MainActor` (UI updates must be on main thread)
- Use `@Published` for state properties
- Keep business logic in ViewModels, not Views
- Use async/await for asynchronous operations

### Model Pattern

**State Models:**
```swift
struct FeatureState {
    let property: Type
    let anotherProperty: Type

    // Initial state
    static let initial = FeatureState(
        property: defaultValue,
        anotherProperty: defaultValue
    )

    // Builder for updates
    func with(
        property: Type? = nil,
        anotherProperty: Type? = nil
    ) -> FeatureState {
        FeatureState(
            property: property ?? self.property,
            anotherProperty: anotherProperty ?? self.anotherProperty
        )
    }
}

// MARK: - Equatable

extension FeatureState: Equatable {
    static func == (lhs: FeatureState, rhs: FeatureState) -> Bool {
        return lhs.property == rhs.property &&
               lhs.anotherProperty == rhs.anotherProperty
    }
}
```

**Data Models:**
```swift
struct DataModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let data: Data

    init(id: UUID = UUID(), name: String, data: Data) {
        self.id = id
        self.name = name
        self.data = data
    }
}
```

### File Organization

**MARK Comments:**
```swift
// MARK: - Properties
// MARK: - Initializer
// MARK: - Body
// MARK: - Actions
// MARK: - Private Helpers
// MARK: - Subcomponents
```

**Extensions:**
```swift
// MARK: - Equatable
// MARK: - Hashable
// MARK: - CustomStringConvertible
```

---

## Design Guidelines for Future Features

### Adding a New Screen

**1. Create Module Structure:**
```
Modules/NewFeature/
├── Views/
│   └── NewFeatureView.swift
├── ViewModels/
│   └── NewFeatureViewModel.swift
└── Models/
    └── NewFeatureState.swift
```

**2. Add Navigation Route:**
```swift
// In Coordinatable.swift
enum CoordinatorRoute: Hashable {
    // ... existing cases
    case newFeature(parameter: Type)
}
```

**3. Add Navigation Method:**
```swift
// In AppCoordinator.swift
func goToNewFeature(with parameter: Type) {
    navigate(to: .newFeature(parameter: parameter))
}
```

**4. Add Navigation Destination:**
```swift
// In SketchyApp.swift
.navigationDestination(for: CoordinatorRoute.self) { route in
    switch route {
    // ... existing cases
    case .newFeature(let parameter):
        NewFeatureView(coordinator: coordinator, parameter: parameter)
    }
}
```

**5. Navigate from Existing View:**
```swift
Button("Open Feature") {
    coordinator.goToNewFeature(with: someParameter)
}
```

### Adding a New Service

**1. Create Service File:**
```swift
// Services/NewService.swift
import Foundation

@MainActor
class NewService: ObservableObject {
    @Published var state: ServiceState

    init() {
        self.state = .initial
    }

    func performAction() async throws {
        // Implementation
    }
}
```

**2. Inject into ViewModel:**
```swift
class FeatureViewModel: ObservableObject {
    private let newService: NewService

    init(newService: NewService = NewService()) {
        self.newService = newService
    }
}
```

**3. Use in View:**
```swift
struct FeatureView: View {
    @StateObject private var service = NewService()

    var body: some View {
        // Use @Published properties from service
    }
}
```

### UI/UX Guidelines

**Visual Consistency:**
- Use SF Symbols for icons
- Follow iOS Human Interface Guidelines
- Maintain 16pt standard padding
- Use system font with appropriate weights
- Blue accent color for interactive elements

**Interaction Patterns:**
- Push navigation for hierarchical content
- Modal sheets for focused tasks
- Confirmation dialogs for destructive actions
- Haptic feedback for important actions

**Accessibility:**
- Add `.accessibilityLabel()` to custom controls
- Support Dynamic Type for text scaling
- Provide VoiceOver descriptions for images
- Ensure minimum touch target size (44x44pt)

### Performance Guidelines

**Metal Rendering:**
- Keep shaders simple and optimized
- Avoid expensive operations in render loop
- Use appropriate pixel formats for textures

**State Updates:**
- Minimize `@Published` property changes
- Batch updates when possible
- Use `@StateObject` vs `@ObservedObject` correctly:
  - `@StateObject` - View owns the object
  - `@ObservedObject` - View receives object from parent

**Memory Management:**
- Clean up resources in `deinit`
- Use weak references to prevent retain cycles
- Dispose of camera session when not needed

---

## Common Patterns & Anti-Patterns

### ✅ DO

**Navigation:**
```swift
// Good - Use coordinator
coordinator.goToDrawing(with: template)

// Good - Use route enum
navigate(to: .drawing(template: template, mode: mode))
```

**State Updates:**
```swift
// Good - Immutable state with builder
state = state.with(opacity: newValue)

// Good - MainActor for ViewModels
@MainActor
class DrawingViewModel: ObservableObject {
    @Published var state: DrawingState
}
```

**View Composition:**
```swift
// Good - Break into subcomponents
VStack {
    Header(title: "Drawing")
    ControlPanel(viewModel: viewModel)
    Footer()
}
```

### ❌ DON'T

**Navigation:**
```swift
// Bad - Direct NavigationLink
NavigationLink(destination: DrawingView(...)) { }

// Bad - Hard-coded navigation paths
navigationPath.append("drawing")
```

**State Management:**
```swift
// Bad - Mutable state
state.opacity = newValue  // ❌ Don't mutate!

// Bad - Publishing everything
@Published var tempValue: Int  // ❌ Only publish essential state
```

**View Logic:**
```swift
// Bad - Business logic in View
var body: some View {
    let result = complexCalculation()  // ❌ Move to ViewModel
    return Text("\(result)")
}
```

---

## Testing Checklist

Before committing changes, verify:

- [ ] Build succeeds for all configurations
- [ ] Navigation flows work correctly (forward and back)
- [ ] State updates propagate to UI
- [ ] Memory leaks checked (Instruments)
- [ ] Camera permissions handled properly
- [ ] Edge cases covered (nil values, errors)
- [ ] UI responds to different screen sizes
- [ ] Accessibility labels present
- [ ] No console warnings or errors

---

## Dependencies & Libraries

**Built-in Frameworks:**
- SwiftUI - UI framework
- Combine - Reactive programming
- Metal - GPU rendering
- AVFoundation - Camera capture
- Photos - Photo library access
- StoreKit - In-app purchases

**No Third-Party Dependencies** - All code is custom-built for maximum control and performance.

---

## Future Enhancement Ideas

1. **Drawing Tools** - Add actual drawing/sketching capability
2. **Undo/Redo** - Track transform history
3. **Grid Overlays** - Add perspective grids
4. **Multiple Templates** - Layer multiple reference images
5. **Custom Templates** - Create templates from camera photos
6. **Social Sharing** - Export completed drawings
7. **Cloud Sync** - Sync templates across devices
8. **Apple Pencil Support** - Pressure-sensitive controls
9. **AR Mode** - Augmented reality template placement
10. **Video Tutorials** - Integrated drawing guides

---

## Quick Reference

**Key File Locations:**
- Navigation: `Coordinators/AppCoordinator.swift`
- Drawing State: `Modules/Drawing/Models/DrawingState.swift`
- Template System: `Modules/Home/Models/TemplateModel.swift`
- Camera Service: `Modules/Camera/Services/CameraService.swift`
- Rendering: `Modules/Rendering/Renderers/MetalRenderer.swift`

**Common Tasks:**
- Add navigation route → Edit `Coordinatable.swift` and `SketchyApp.swift`
- Modify drawing controls → Edit `Modules/Drawing/Views/ControlPanelView.swift`
- Update templates → Edit `Modules/Home/Models/TemplateModel.swift`
- Change rendering → Edit `Modules/Rendering/Renderers/`

**Important Constants:**
- Default opacity: 0.5 (50%)
- Default brightness: 0.5 (50%)
- Transform identity: `Transform.identity`
- Standard corner radius: 12pt
- Standard padding: 16pt

---

*Last Updated: February 2026*
*Version: 1.0*
*Architecture: MVVM + Coordinator*
*Minimum iOS: 17.0*
