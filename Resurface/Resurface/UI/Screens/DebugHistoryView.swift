import SwiftUI

/// A developer-facing view to inspect the state of Resurface's resurfacing logic.
///
/// **Purpose**:
/// - visual verification that items are being stored correctly.
/// - trigger the behaviour engine to see what it would pick next.
/// - debugging metadata like timestamps and counters.
struct DebugHistoryView: View {
    
    // Ideally injected via environment
    @EnvironmentObject var storage: StorageManager
    
    // The engine is stateless, so we can just hold a local instance or get it from environment.
    // For simplicity, let's assume it's passed in or we create a local one for testing.
    let engine = BehaviourEngine()
    
    // State for the "Best Item" experiment
    @State private var selectedStack: StackType = .food
    @State private var bestItemResult: StoredItem?
    @State private var bestItemScoreParams: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 1. Control Panel for Behaviour Engine
                VStack(spacing: 10) {
                    Text("Behaviour Simulation")
                        .font(.headline)
                    
                    Picker("Stack", selection: $selectedStack) {
                        ForEach(StackType.allCases, id: \.self) { stack in
                            Text(stack.displayName).tag(stack)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button("Find Best Item") {
                        runBehaviourEngine()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let best = bestItemResult {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Winner: \(best.textSnippet ?? "Untitled")")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("ID: ...\(best.id.uuidString.suffix(4))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("No suitable item found (or none stored)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                // 2. List of All Items
                List {
                    ForEach(storage.items, id: \.id) { item in
                        ItemRowView(item: item)
                    }
                }
            }
            .navigationTitle("Debug History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // No-op for in-memory, but would refetch in Core Data
                        _ = storage.fetchAllItems()
                    }
                }
            }
        }
    }
    
    private func runBehaviourEngine() {
        // Ask the engine for the best item in the selected stack right now
        let result = engine.bestItem(
            for: selectedStack,
            at: Date(),
            from: storage.items
        )
        self.bestItemResult = result
    }
}

