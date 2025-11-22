//
//  ResurfaceApp.swift
//  Resurface
//
//  Created by Raja Dhanda on 22/11/2025.
//

import SwiftUI

/// The main entry point for the Resurface application.
///
/// **Responsibility**:
/// - Initialize the core services (Storage, Logic).
/// - Inject dependencies into the view hierarchy.
/// - Set up any global app state or background tasks.
@main
struct ResurfaceApp: App {
    
    // Initialize the single source of truth for storage.
    // Using @StateObject ensures it lives for the lifecycle of the app.
    @StateObject private var storageManager = StorageManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storageManager)
        }
    }
}
