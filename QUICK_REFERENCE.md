# Sketchy - Quick Reference

## Navigation Cheat Sheet

### Current Routes
```swift
case home                           // Home screen (template selection)
case modeSelection(template: ...)   // Mode selection screen
case drawing(template:, mode:)      // Drawing interface
case templateGallery                // Template gallery
```

### Navigation Commands
```swift
// From any view with @ObservedObject var coordinator: AppCoordinator

coordinator.goToDrawing(with: template)              // → ModeSelection
coordinator.goToModeSelection(with: template)        // → ModeSelection
coordinator.goToDrawing(with: template, mode: .abovePaper)  // → Drawing
coordinator.goToTemplateGallery()                    // → Gallery
coordinator.goBack()                                // ← Back
coordinator.goToHome()                              // ←← Home
```

### Adding New Route

1. **Coordinatable.swift** - Add case to enum
2. **AppCoordinator.swift** - Add `goToNewRoute()` method
3. **SketchyApp.swift** - Add case in `.navigationDestination`
4. **Call it** - `coordinator.goToNewRoute()`

---

## State Management Patterns

### Immutable State with Builder
```swift
// Define state
struct MyState {
    let value: Type
    let anotherValue: Type

    func with(value: Type? = nil, anotherValue: Type? = nil) -> MyState {
        MyState(
            value: value ?? self.value,
            anotherValue: anotherValue ?? self.anotherValue
        )
    }
}

// Update state
state = state.with(value: newValue)  // ✅ Immutable
state.value = newValue               // ❌ Don't mutate!
```

### ViewModel Template
```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var state: MyState

    init(initialState: MyState = .initial) {
        self.state = initialState
    }

    func updateValue(_ newValue: Type) {
        state = state.with(value: newValue)
    }
}
```

---

## Drawing Modes

### Above Paper (Camera)
```swift
DrawingState.DrawingMode.abovePaper
```
- Camera feed background
- Template overlay
- Flashlight toggle
- Camera transforms

### Under Paper (Lightbox)
```swift
DrawingState.DrawingMode.underPaper
```
- White background
- Template overlay
- Brightness control
- No camera

---

## Template Sources

```swift
// Bundled asset
TemplateModel(name: "Cat", bundledAssetName: "cat")

// Remote URL
TemplateModel(name: "Dog", bundledAssetName: "https://example.com/dog.png")

// User imported
TemplateModel(name: "My Photo", imageData: photoData)
```

---

## File Templates

### New SwiftUI View
```swift
import SwiftUI

struct FeatureView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel: FeatureViewModel

    init(coordinator: AppCoordinator, dependency: Type) {
        self.coordinator = coordinator
        self._viewModel = StateObject(
            wrappedValue: FeatureViewModel(dependency: dependency)
        )
    }

    var body: some View {
        VStack {
            Text("Feature")
        }
    }
}
```

### New ViewModel
```swift
import Foundation
import SwiftUI
import Combine

@MainActor
class FeatureViewModel: ObservableObject {
    @Published var state: FeatureState

    init(dependency: Type) {
        self.state = FeatureState(dependency: dependency)
    }
}
```

### New State Model
```swift
import Foundation

struct FeatureState {
    let property: Type

    static let initial = FeatureState(
        property: defaultValue
    )

    func with(property: Type? = nil) -> FeatureState {
        FeatureState(
            property: property ?? self.property
        )
    }
}

extension FeatureState: Equatable {
    static func == (lhs: FeatureState, rhs: FeatureState) -> Bool {
        lhs.property == rhs.property
    }
}
```

---

## Common UI Components

### Button with Styling
```swift
Button(action: { /* action */ }) {
    Text("Continue")
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
}
```

### Back Button
```swift
Button(action: { coordinator.goBack() }) {
    Image(systemName: "chevron.left")
        .foregroundColor(.white)
        .padding()
        .background(Color.black.opacity(0.5))
        .clipShape(Circle())
}
```

### Slider
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Value: \(Int(value * 100))%")
        .font(.caption)
        .foregroundColor(.white)

    Slider(value: Binding(
        get: { value },
        set: { onChange($0) }
    ), in: 0...1)
    .tint(.blue)
}
```

---

## Transform System

```swift
struct Transform {
    var scale: CGFloat
    var rotation: Double      // in radians
    var translation: CGPoint

    static let identity = Transform(
        scale: 1.0,
        rotation: 0.0,
        translation: .zero
    )
}

// Apply to view
View
    .scaleEffect(transform.scale)
    .rotationEffect(Angle(radians: transform.rotation))
    .offset(transform.translation)
```

---

## Service Access

### Camera
```swift
@StateObject private var cameraService = CameraService()
cameraService.startSession()
cameraService.stopSession()
```

### Flashlight
```swift
let flashlightService = FlashlightService()
flashlightService.toggle(isOn: true)
```

### Brightness
```swift
let brightnessService = BrightnessService()
brightnessService.setBrightness(0.5)
```

### Auto Lock
```swift
let autoLockService = AutoLockService()
autoLockService.disableAutoLock()  // Keep screen on
autoLockService.enableAutoLock()
```

---

## Module Structure Template

```
Modules/NewFeature/
├── Views/
│   └── NewFeatureView.swift           # UI implementation
├── ViewModels/
│   └── NewFeatureViewModel.swift      # State & logic
└── Models/
    └── NewFeatureState.swift          # State definition
```

---

## Key Constants

```swift
// Opacity & Brightness
opacity: 0.0 ... 1.0        // Default: 0.5
brightness: 0.0 ... 1.0     // Default: 0.5

// Transforms
scale: 0.1 ... 3.0          // Default: 1.0
rotation: 0 ... 2π          // Default: 0.0
translation: CGPoint        // Default: .zero

// UI
cornerRadius: 12            // Standard
padding: 16                 // Standard
shadowRadius: 4             // Subtle
shadowRadius: 8             // Prominent

// Animation
.spring(response: 0.3)     // Selection
.easeInOut(duration: 0.3)  // UI fade
```

---

## Debugging

### Print State
```swift
print("""
State:
  Mode: \(state.mode)
  Opacity: \(state.opacity)
  Transform: \(state.templateTransform)
""")
```

### Check Navigation
```swift
print("Path count: \(coordinator.navigationPath.count)")
print("Current route: \(coordinator.navigationPath.last)")
```

### Monitor Services
```swift
// Camera
cameraService.delegate = self
func cameraService(_: CameraService, didUpdateFrame buffer: CVBuffer) {
    // Frame received
}

// Subscription
subscriptionManager.$isSubscribed
    .sink { isSubscribed in
        print("Subscribed: \(isSubscribed)")
    }
```

---

## Common Issues & Solutions

### Issue: "Type does not conform to ObservableObject"
**Fix:** Add `import Combine`

### Issue: "Cannot convert value type"
**Fix:** Use `@StateObject` instead of `@ObservedObject` for view-owned objects

### Issue: Navigation not working
**Fix:**
1. Check route is in enum
2. Check `.navigationDestination` has case
3. Verify `coordinator` is passed as `@ObservedObject`

### Issue: State not updating UI
**Fix:**
1. Mark property `@Published`
2. Mark ViewModel `@MainActor`
3. Update state using `with()` method

### Issue: Camera not showing
**Fix:**
1. Check permissions in Settings
2. Call `cameraService.startSession()`
3. Verify mode is `.abovePaper`

---

## Git Commit Message Style

```
feat: add mode selection screen
fix: camera permission handling
refactor: simplify state management
docs: update project guidelines
style: format SwiftUI views
perf: optimize metal rendering
test: add navigation flow tests
chore: update dependencies
```

---

*Last Updated: February 2026*
