//
//  TutorialView.swift
//  Sketchy
//
//  Created by Kazi Mashry on 5/3/26.
//

import SwiftUI

// MARK: - Tutorial View

struct TutorialView: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator

    // MARK: - State
    @State private var currentPage = 0

    // MARK: - Body
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Drag Gesture Tutorial
            TutorialDragPage(coordinator: coordinator, isNextEnabled: bindingForPage(0))
                .tag(0)

            // Page 2: Blank (for future gesture tutorial)
            TutorialBlankPage(coordinator: coordinator)
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarBackButtonHidden(true)
    }

    // Helper to create binding for each page
    private func bindingForPage(_ page: Int) -> Binding<Bool> {
        Binding(
            get: { false }, // Not used currently
            set: { _ in }
        )
    }
}

// MARK: - Tutorial Drag Page (Page 1)

struct TutorialDragPage: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator
    @Binding var isNextEnabled: Bool

    // MARK: - State
    @State private var boxOffset = CGSize.zero
    @State private var hasDragged = false
    @State private var showMessage = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.clear

            VStack(spacing: 0) {
                // Skip button at top right
                HStack {
                    Spacer()
                    Button("Skip") {
                        coordinator.goToFinalOnboarding()
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                Spacer()

                // Mascot with speech bubble
                VStack(spacing: 16) {
                    // Speech bubble
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "quote.opening")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(showMessage ? "Good Job!" : "Drag the box to move")
                                    .font(.body)
                                    .fontWeight(.regular)
                                    .foregroundColor(.primary)

                                Image(systemName: "quote.closing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .frame(width: 220, height: 60)
                    .overlay(
                        // Speech bubble tail
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(45))
                            .offset(x: 20, y: -8),
                        alignment: .topLeading
                    )

                    // Mascot
                    Image("mascot_1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(showMessage ? 10 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showMessage)
                }
                .padding(.bottom, 40)

                Spacer()

                // Draggable gray box
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(width: 200, height: 200)
                    .offset(boxOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                boxOffset = value.translation
                            }
                            .onEnded { _ in
                                // Check if dragged enough (threshold: 30 points)
                                if abs(boxOffset.width) > 30 || abs(boxOffset.height) > 30 {
                                    if !hasDragged {
                                        hasDragged = true
                                        withAnimation(.spring(response: 0.3)) {
                                            showMessage = true
                                        }
                                    }
                                }
                                // Snap back to center
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    boxOffset = .zero
                                }
                            }
                    )

                Spacer()
                    .frame(height: 60)

                // Next button at bottom right
                HStack {
                    Spacer()
                    Button(action: {
                        // Navigate to next page (will be handled by parent)
                    }) {
                        ZStack {
                            Circle()
                                .fill(hasDragged ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)

                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!hasDragged)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Tutorial Blank Page (Page 2)

struct TutorialBlankPage: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                // Skip button at top right
                HStack {
                    Spacer()
                    Button("Skip") {
                        coordinator.goToFinalOnboarding()
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                Spacer()

                Text("Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary)

                Spacer()

                // Next button at bottom right
                HStack {
                    Spacer()
                    Button(action: {
                        coordinator.goToFinalOnboarding()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)

                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TutorialView(coordinator: AppCoordinator())
}
