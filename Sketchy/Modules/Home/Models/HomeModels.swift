import Foundation

/// Home tab enumeration
enum HomeTab: String, CaseIterable {
    case home = "Home"
    case favorites = "Favorites"
    case projects = "Projects"
    case colorbook = "Colorbook"
    
    func iconName() -> String {
        switch self {
        case .home:
            return "house.fill"
        case .favorites:
            return "star.fill"
        case .projects:
            return "folder.fill"
        case .colorbook:
            return "paintbrush.pointed.fill"
        }
    }
}
