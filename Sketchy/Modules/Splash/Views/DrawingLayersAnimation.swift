//
//  DrawingLayersAnimation.swift
//  Sketchy
//
//  Created by Kazi Mashry on 2/3/26.
//

import SwiftUI

struct DrawingLayersAnimation: View {

    let onAnimationComplete: () -> Void

    @State private var showBG = false
    @State private var showSketchbook = false
    @State private var showCat = false
    @State private var showPencil = false

    var body: some View {
        ZStack {

            // Background
            Image("bg_gradient")
                .resizable()
                .scaledToFit()
                .opacity(showBG ? 1 : 0)
                .scaleEffect(showBG ? 1 : 0.95)
                .animation(.easeOut(duration: 0.5), value: showBG)

            // Sketchbook (main focus)
            Image("sketchbook")
                .resizable()
                .scaledToFit()
                .scaleEffect(showSketchbook ? 0.9 : 0.75)
                .rotationEffect(.degrees(showSketchbook ? 0 : -6))
                .offset(y: showSketchbook ? 0 : -30)
                .opacity(showSketchbook ? 1 : 0)
                .animation(
                    .spring(response: 0.7, dampingFraction: 0.8),
                    value: showSketchbook
                )

            // Cat card (smaller)
            Image("cat_card")
                .resizable()
                .scaledToFit()
                .scaleEffect(showCat ? 0.65 : 0.4)
                .opacity(showCat ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.75),
                    value: showCat
                )

            // Pencil (smaller & subtly offset final position)
            Image("pencil")
                .resizable()
                .scaledToFit()
                .scaleEffect(showPencil ? 0.5 : 0.3)
                .rotationEffect(.degrees(showPencil ? 0 : -25))
                .offset(
                    x: showPencil ? 50 : 70,
                    y: showPencil ? -15 : 70
                )
                .opacity(showPencil ? 1 : 0)
                .animation(
                    .easeOut(duration: 0.45),
                    value: showPencil
                )
        }
        .onAppear {
            playSequence()
        }
    }

    private func playSequence() {
        showBG = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showSketchbook = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showCat = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.45)) {
                showPencil = true
            }

            // Animation complete - wait for pencil animation to finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onAnimationComplete()
            }
        }
    }
}
