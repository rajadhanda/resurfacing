import Foundation
import Combine

/// Protocol defining the contract for storage operations.
///
/// Allows for dependency injection and easier testing/mocking.
/// Future implementations can swap the in-memory store for Core Data or SwiftData.
protocol StorageManaging {
    /// Fetch all stored items.
    func fetchAllItems() -> [StoredItem]
    
    /// Save a new item.
    func save(_ item: StoredItem)
    
    /// Update an existing item.
    func update(_ item: StoredItem)
}

/// A concrete implementation of `StorageManaging` that keeps items in memory.
///
/// **Purpose**:
/// - Acts as the "source of truth" for the app in this MVP phase.
/// - Conforms to `ObservableObject` so SwiftUI views can react to changes (e.g. `@Published items`).
/// - Seeds initial data for debugging purposes.
///
/// **Thread Safety**:
/// - Operations are currently on the main thread for simplicity as it's `@Published`.
/// - In a real DB implementation, fetching might be async.
class StorageManager: ObservableObject, StorageManaging {
    
    /// The in-memory cache of items.
    /// Published so that views observing this object update automatically.
    @Published var items: [StoredItem] = []
    
    init() {
        // Seed with sample data for Feature 0 verification
        seedData()
    }
    
    // MARK: - StorageManaging
    
    func fetchAllItems() -> [StoredItem] {
        return items
    }
    
    func save(_ item: StoredItem) {
        // Check for duplicates to prevent overwriting or double-adding if ID exists
        if items.contains(where: { $0.id == item.id }) {
            print("[StorageManager] Warning: Attempted to save duplicate item \(item.id). Use update() instead.")
            return
        }
        items.append(item)
    }
    
    func update(_ item: StoredItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            print("[StorageManager] Warning: Attempted to update non-existent item \(item.id). Saving as new.")
            items.append(item)
        }
    }
    
    // MARK: - Seeding
    
    private func seedData() {
        // Helper to make dates relative to now
        let now = Date()
        let oneDay: TimeInterval = 86400
        
        let foodItem = StoredItem(
            id: UUID(),
            createdAt: now.addingTimeInterval(-oneDay * 2), // 2 days ago
            category: .recipe,
            stack: .food,
            triggerType: .quickSave,
            url: URL(string: "https://allrecipes.com/pasta"),
            textSnippet: "Delicious Pasta Carbonara Recipe",
            state: .fresh,
            timesDismissed: 0,
            timesActedOn: 0,
            lastShownAt: nil,
            lastActionAt: nil
        )
        
        let bodyItem = StoredItem(
            id: UUID(),
            createdAt: now.addingTimeInterval(-oneDay * 5), // 5 days ago
            category: .workout,
            stack: .body,
            triggerType: .shareExtension,
            url: URL(string: "https://youtube.com/workout"),
            textSnippet: "15 Min HIIT Workout",
            state: .fresh,
            timesDismissed: 0,
            timesActedOn: 0,
            lastShownAt: nil,
            lastActionAt: nil
        )
        
        let mindItem = StoredItem(
            id: UUID(),
            createdAt: now.addingTimeInterval(-3600), // 1 hour ago
            category: .quote,
            stack: .mind,
            triggerType: .quickSave,
            url: nil,
            textSnippet: "“The only way to do great work is to love what you do.”",
            state: .acted, // Already acted on once
            timesDismissed: 0,
            timesActedOn: 1,
            lastShownAt: now.addingTimeInterval(-1800), // Shown 30 mins ago
            lastActionAt: now.addingTimeInterval(-1700)
        )
        
        let readingItem = StoredItem(
            id: UUID(),
            createdAt: now, // Just now
            category: .reading,
            stack: .reading,
            triggerType: .shareExtension,
            url: URL(string: "https://news.ycombinator.com"),
            textSnippet: "Show HN: Resurface App",
            state: .fresh,
            timesDismissed: 0,
            timesActedOn: 0,
            lastShownAt: nil,
            lastActionAt: nil
        )
        
        items = [foodItem, bodyItem, mindItem, readingItem]
        print("[StorageManager] Seeded \(items.count) items.")
    }
}

