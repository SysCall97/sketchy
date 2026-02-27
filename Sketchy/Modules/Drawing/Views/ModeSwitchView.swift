import SwiftUI

/// Mode switcher - Toggle between Above Paper and Under Paper modes
struct ModeSwitchView: View {
    let currentMode: DrawingState.DrawingMode
    let onModeChange: (DrawingState.DrawingMode) -> Void

    var body: some View {
        Picker("Mode", selection: Binding(
            get: { currentMode },
            set: { onModeChange($0) }
        )) {
            Text("Above Paper").tag(DrawingState.DrawingMode.abovePaper)
            Text("Under Paper").tag(DrawingState.DrawingMode.underPaper)
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
}
