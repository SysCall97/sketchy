//
//  SketchyApp.swift
//  Sketchy
//
//  Created by Kazi Mashry on 27/2/26.
//

import SwiftUI
import AVFoundation
import Photos
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct SketchyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: appCoordinator)
        }
    }
}

/// Root view that observes coordinator changes and displays the correct screen
struct RootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            coordinator.rootView
                .navigationDestination(for: CoordinatorRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView(coordinator: coordinator)
                    case .modeSelection(let template):
                        ModeSelectionView(coordinator: coordinator, template: template)
                    case .drawing(let template, let mode):
                        DrawingView(coordinator: coordinator, template: template, initialMode: mode)
                    case .templateGallery:
                        TemplateGalleryView(coordinator: coordinator)
                    }
                }
        }
    }
}
