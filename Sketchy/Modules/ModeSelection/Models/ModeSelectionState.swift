import Foundation

/// Represents the state for mode selection
struct ModeSelectionState {
    enum DrawingMode: String, CaseIterable {
        case abovePaper = "Draw with camera"
        case underPaper = "Draw with screen"

        var displayName: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .abovePaper: return "camera.viewfinder"
            case .underPaper: return "iphone"
            }
        }

        var description: String {
            switch self {
            case .abovePaper:
                return "Overlay template on camera feed for tracing"
            case .underPaper:
                return "Use white screen as a lightbox"
            }
        }

        /// Convert to DrawingState.DrawingMode
        var toDrawingMode: DrawingState.DrawingMode {
            switch self {
            case .abovePaper: return .abovePaper
            case .underPaper: return .underPaper
            }
        }
    }
}
