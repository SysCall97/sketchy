//
//  SketchyApp.swift
//  Sketchy
//
//  Created by Kazi Mashry on 27/2/26.
//

import SwiftUI
import AVFoundation
import Photos

@main
struct SketchyApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var showPermissionsAlert = false
    @State private var permissionDeniedMessage = ""

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: appCoordinator)
                .onAppear {
                    requestPermissionsOnFirstLaunch()
                }
                .alert("Permissions Required", isPresented: $showPermissionsAlert) {
                    Button("OK") {
                        showPermissionsAlert = false
                    }
                    Button("Settings") {
                        openAppSettings()
                    }
                } message: {
                    Text(permissionDeniedMessage)
                }
        }
    }

    // MARK: - Permissions

    private func requestPermissionsOnFirstLaunch() {
        let hasRequestedBefore = UserDefaults.standard.bool(forKey: "hasRequestedPermissions")

        if !hasRequestedBefore {
            // Mark as requested
            UserDefaults.standard.set(true, forKey: "hasRequestedPermissions")

            // Request permissions
            Task {
                await requestAllPermissions()
            }
        }
    }

    @MainActor
    private func requestAllPermissions() async {
        // Request Camera Permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                showPermissionAlert(for: "Camera access is needed for the Above Paper drawing mode.")
            }
        case .denied, .restricted:
            showPermissionAlert(for: "Camera access is needed for the Above Paper drawing mode. Please enable it in Settings.")
        case .authorized:
            break
        @unknown default:
            break
        }

        // Request Photo Library Permission
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch photoStatus {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status != .authorized && status != .limited {
                showPermissionAlert(for: "Photo library access is needed to import your own drawing templates.")
            }
        case .denied, .restricted:
            showPermissionAlert(for: "Photo library access is needed to import your own drawing templates. Please enable it in Settings.")
        case .authorized, .limited:
            break
        @unknown default:
            break
        }
    }

    private func showPermissionAlert(for message: String) {
        permissionDeniedMessage = message
        showPermissionsAlert = true
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

/// Root view that observes coordinator changes and displays the correct screen
struct RootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        coordinator.rootView
    }
}
