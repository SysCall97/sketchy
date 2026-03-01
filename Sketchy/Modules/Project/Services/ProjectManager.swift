import Foundation

/// Manager for project persistence using UserDefaults
class ProjectManager {

    static let shared = ProjectManager()

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let projects = "savedProjects"
    }

    // MARK: - Public Methods

    /// Save all projects to UserDefaults
    func saveProjects(_ projects: [ProjectModel]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projects)
            UserDefaults.standard.set(data, forKey: Keys.projects)
            print("ProjectManager: Saved \(projects.count) projects")
        } catch {
            print("ProjectManager: Failed to save projects - \(error)")
        }
    }

    /// Load all projects from UserDefaults
    func loadProjects() -> [ProjectModel] {
        guard let data = UserDefaults.standard.data(forKey: Keys.projects) else {
            print("ProjectManager: No projects found")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let projects = try decoder.decode([ProjectModel].self, from: data)
            print("ProjectManager: Loaded \(projects.count) projects")
            return projects
        } catch {
            print("ProjectManager: Failed to load projects - \(error)")
            return []
        }
    }

    /// Add a new project
    func addProject(_ project: ProjectModel, isPremium: Bool) -> Bool {
        var projects = loadProjects()

        // Check limit for free users
        if !isPremium && projects.count >= 1 {
            print("ProjectManager: Free user limit reached")
            return false
        }

        projects.append(project)
        saveProjects(projects)

        // Mark that free user has saved a project
        if !isPremium {
            KeychainManager.shared.setHasSavedProject(true)
        }

        return true
    }

    /// Delete a project
    func deleteProject(_ project: ProjectModel) {
        var projects = loadProjects()
        projects.removeAll { $0.id == project.id }
        saveProjects(projects)

        // Update Keychain if no projects left for free user
        if projects.isEmpty && !KeychainManager.shared.isPremiumUser() {
            KeychainManager.shared.setHasSavedProject(false)
        }

        print("ProjectManager: Deleted project \(project.name)")
    }

    /// Get project by ID
    func getProject(id: UUID) -> ProjectModel? {
        return loadProjects().first { $0.id == id }
    }

    /// Check if user can save more projects
    func canSaveProject(isPremium: Bool) -> Bool {
        if isPremium {
            return true
        }
        return loadProjects().count < 1
    }
}
