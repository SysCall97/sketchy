import SwiftUI

/// Alert view for saving projects with name input
struct ProjectSaveAlertView: View {
    @Binding var isPresented: Bool
    let templateID: UUID
    let currentState: DrawingState
    let onSave: (String) -> Void
    let onExit: () -> Void

    @State private var projectName: String = ""
    @State private var showLimitAlert = false

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap - must choose Save or Exit
                }

            // Alert content
            VStack(spacing: 20) {
                // Title
                Text("Save as Project?")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Description
                Text("Save your current work to continue later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Project name input
                TextField("Project Name", text: $projectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        onExit()
                    }) {
                        Text("Exit")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        handleSave()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(projectName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(projectName.isEmpty)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .alert("Limit Reached", isPresented: $showLimitAlert) {
            Button("Purchase", role: .none) {
                // This will be handled by parent showing paywall
                isPresented = false
            }
            Button("Exit", role: .cancel) {
                isPresented = false
                onExit()
            }
        } message: {
            Text("Free users can save only one project. Upgrade to premium for unlimited projects.")
        }
    }

    private func handleSave() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Check limit in parent via callback
        onSave(name)
    }
}

#Preview {
    StatefulPreviewWrapper()
}

private struct StatefulPreviewWrapper: View {
    @State private var isPresented = true

    var body: some View {
        ProjectSaveAlertView(
            isPresented: $isPresented,
            templateID: UUID(),
            currentState: DrawingState.initial
        ) { _ in
            print("Save tapped")
        } onExit: {
            print("Exit tapped")
        }
    }
}
