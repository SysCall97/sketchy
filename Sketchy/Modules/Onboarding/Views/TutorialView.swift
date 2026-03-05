//
//  TutorialView.swift
//  Sketchy
//
//  Created by Kazi Mashry on 5/3/26.
//

import SwiftUI

// MARK: - Mascot With Speech View Component

struct MascotWithSpeechView: View {
    // MARK: - Binding
    @Binding var message: String

    // MARK: - State
    @State private var textSize: CGSize = .zero
    @State private var isAnimating = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Speech bubble with dynamic sizing
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(45))
                    .offset(y: textSize.height - 4)
                
                // Background bubble
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Text with quotes
                HStack(spacing: 4) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(message)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .background(
                            // Hidden text view to measure size
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: TextSizePreferenceKey.self, value: textSize)
                            }
                        )
                        .onAppear {
                            // Trigger size calculation
                            textSize = calculateTextSize(containerWidth: 300)
                        }

                    Image(systemName: "quote.closing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                
            }
            .frame(width: textSize.width + 40, height: textSize.height + 20)
            .padding(.bottom, 8)

            // Mascot
            Image("mascot_1")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(isAnimating ? 10 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        }
        .onChange(of: message) { _ in
            // Recalculate size when message changes
            withAnimation(.easeInOut(duration: 0.2)) {
                textSize = calculateTextSize(containerWidth: 300)
                isAnimating = true
            }
        }
    }

    // MARK: - Private Methods

    private func calculateTextSize(containerWidth: CGFloat) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]

        let text = message as NSString
        let maxWidth = containerWidth - 40 // account for padding

        var size = text.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        ).size

        // Limit to 2 lines
        let lineHeight = font.lineHeight * 2
        if size.height > lineHeight {
            size.height = lineHeight
        }

        // Ensure minimum size
        size.width = max(size.width + 60, 100)
        size.height = max(size.height, 30)

        return size
    }
}

// MARK: - Text Size Preference Key

struct TextSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

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
            get: { false },
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
    @State private var lastOffset = CGSize.zero
    @State private var hasDragged = false
    @State private var showMessage = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.white

            // Draggable gray box (at the back - lowest z-index)
            // Positioned in center initially, can be dragged anywhere
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(width: 200, height: 200)
                    .position(
                        x: geometry.size.width / 2 + boxOffset.width,
                        y: geometry.size.height / 2 + boxOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Smooth drag: add translation to last offset
                                boxOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                // Save the final offset for next drag
                                lastOffset = boxOffset

                                // Check if dragged enough (threshold: 30 points from center)
                                let totalDrag = sqrt(pow(boxOffset.width, 2) + pow(boxOffset.height, 2))
                                if totalDrag > 30 {
                                    if !hasDragged {
                                        hasDragged = true
                                        withAnimation(.spring(response: 0.3)) {
                                            showMessage = true
                                        }
                                    }
                                }
                            }
                    )
            }

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

                Spacer().frame(height: 50)

                // Mascot with speech bubble using new component
                MascotWithSpeechView(
                    message: Binding(
                        get: { showMessage ? "You have dragged successfully!" : "Drag the box to move" },
                        set: { _ in }
                    )
                )
                .padding(.bottom, 40)

                Spacer()

                // Next button at bottom right
                HStack {
                    Spacer()
                    Button(action: {
                        // Navigate to next page (will be handled by parent)
                    }) {
                        ZStack {
                            Circle()
                                .fill(hasDragged ? LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
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
        .ignoresSafeArea()
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
