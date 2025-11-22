import SwiftUI

/// The root container of the application UI.
///
/// **Purpose**:
/// - Holds top-level state and environment objects.
/// - Directs the user to the appropriate initial screen.
/// - For Feature 0, this simply wraps the DebugHistoryView.
struct RootView: View {
    
    // In a real app, this might manage tabs or navigation stacks.
    // For now, it just passes dependencies down.
    
    var body: some View {
        // In the future, we might check if onboarding is needed, etc.
        DebugHistoryView()
    }
}

