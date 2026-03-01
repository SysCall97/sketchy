import SwiftUI

/// View for displaying and managing saved projects
struct ProjectsListView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var projects: [ProjectModel] = []
    @State private var showDeleteAlert = false
    @State private var projectToDelete: ProjectModel?

    var body: some View {
        Group {
            if projects.isEmpty {
                emptyProjectsState
            } else {
                projectGrid
            }
        }
        .onAppear {
            loadProjects()
        }
    }

    private var projectGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                Text("Your Projects")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)

                // Projects grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(projects) { project in
                        ProjectThumbnail(
                            project: project,
                            template: getTemplate(for: project.templateID),
                            onTap: {
                                openProject(project)
                            },
                            onDelete: {
                                projectToDelete = project
                                showDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
                    .frame(height: 100)
            }
        }
        .alert("Delete Project", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("Are you sure you want to delete this project?")
        }
    }

    private var emptyProjectsState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("No Projects Yet")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Save your drawings as projects to continue working on them later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func loadProjects() {
        projects = ProjectManager.shared.loadProjects()
    }

    private func getTemplate(for id: UUID) -> TemplateModel? {
        // Try to find in local templates
        let allTemplates = TemplateModel.localTemplates + FirebaseManager.shared.remoteTemplates
        return allTemplates.first { $0.id == id }
    }

    private func openProject(_ project: ProjectModel) {
        guard let template = getTemplate(for: project.templateID) else {
            print("ProjectsListView: Template not found for project")
            return
        }

        let drawingState = project.toDrawingState()
        coordinator.goToDrawing(with: template, initialState: drawingState)
    }

    private func deleteProject() {
        guard let project = projectToDelete else { return }

        ProjectManager.shared.deleteProject(project)
        projects.removeAll { $0.id == project.id }
        projectToDelete = nil
    }
}

/// Project thumbnail component
struct ProjectThumbnail: View {
    let project: ProjectModel
    let template: TemplateModel?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail image
            ZStack(alignment: .topTrailing) {
                if let template = template {
                    CachedAsyncImage(url: template.remoteURL, localImage: template.image)
                } else {
                    // Template not found placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))

                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    }
                }

                // Delete button
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(8)
            }

            // Project name
            Text(project.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)

            // Date
            Text(project.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
