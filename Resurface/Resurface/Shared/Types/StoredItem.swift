import Foundation

/// Canonical representation of a saved item in Resurface.
///
/// **Purpose**:
/// - This is the primary domain model used throughout the app after capture and classification.
/// - Serves as the interface between Storage, Behaviour Engine, and UI layers.
/// - Contains all metadata needed for resurfacing logic and user interaction tracking.
///
/// **Design Philosophy**:
/// - Immutable value type (all properties are `let`).
/// - Framework-agnostic: no UIKit, SwiftUI, or Core Data imports.
/// - Updates to items (e.g., state changes, counter increments) happen by creating
///   new instances with modified values, not by mutation.
/// - Reading items are treated identically to other categories here; the
///   `category` + `stack` pair is what informs downstream behaviour and widget
///   presentation.
///
/// **Mapping to Core Data**:
/// - A separate layer (Storage) handles conversion between `StoredItem` and Core Data entities.
/// - This keeps domain types clean and testable without database dependencies.
///
/// **Edge Cases**:
/// - `url` and `textSnippet` may both be `nil`. UI and Behaviour Engine must handle
///   these gracefully (e.g., by showing a placeholder or treating as low-priority).
/// - `lastShownAt` and `lastActionAt` are `nil` for fresh items that have never
///   been surfaced or acted upon.
/// - Counters (`timesDismissed`, `timesActedOn`) can be zero even for non-fresh items
///   if the state transition happened without incrementing the counter (edge case in
///   older versions or migration scenarios).
struct StoredItem: Codable, Equatable {
    /// Stable identifier for the item.
    ///
    /// This UUID is carried over from the original `CaptureEvent.id`, ensuring
    /// end-to-end traceability from capture through storage and resurfacing.
    let id: UUID
    
    /// When the item was first created in storage.
    ///
    /// This timestamp represents when the item was successfully saved after
    /// classification, not necessarily when it was originally captured (though
    /// typically these are very close in time).
    ///
    /// Used for:
    /// - Sorting items chronologically.
    /// - Calculating item age for resurfacing priority.
    let createdAt: Date
    
    /// Semantic category predicted for the item (recipe, workout, quote, none).
    ///
    /// Determines the type of content and influences how it's presented in UI
    /// and when it's resurfaced by the behaviour engine.
    let category: ItemCategory
    
    /// High-level stack bucket (food, body, mind, other).
    ///
    /// Provides coarse grouping for:
    /// - UI theming and organization.
    /// - Time-based resurfacing rules (e.g., food items in evening, workouts in morning).
    let stack: StackType
    
    /// How the item was originally captured (Quick Save / Share Extension).
    ///
    /// Preserved for analytics and debugging. May inform future feature development
    /// by showing which capture methods are most popular.
    let triggerType: CaptureTriggerType
    
    /// Original URL of the content, if any.
    ///
    /// **Edge Case**: May be `nil` if:
    /// - Original capture had no URL (e.g., plain text, screenshot).
    /// - URL was invalid or could not be preserved.
    ///
    /// **UI Handling**: When `nil`, UI should either:
    /// - Show only the text snippet.
    /// - Provide a disabled/greyed-out "Open" button.
    /// - Fall back to a generic action.
    let url: URL?
    
    /// Short text snippet used as a preview/title in UI.
    ///
    /// This is typically:
    /// - The first line or first ~100 characters of the captured text.
    /// - A cleaned version of the `rawText` from the `CaptureEvent`.
    ///
    /// **Edge Case**: May be `nil` if no text was available at capture time.
    ///
    /// **UI Handling**: When `nil`, UI should show:
    /// - A placeholder like "No preview available".
    /// - Just the URL domain if available.
    /// - The stack emoji as a fallback.
    let textSnippet: String?
    
    /// Current lifecycle state of the item from the user's perspective.
    ///
    /// Determines whether the item is fresh, has been engaged with, or has been dismissed.
    /// The behaviour engine uses this to prioritize resurfacing:
    /// - `.fresh` items are highest priority.
    /// - `.acted` items may be shown again but less frequently.
    /// - `.dismissed` items are deprioritized but not permanently hidden.
    let state: ItemState
    
    /// Number of times the item has been explicitly dismissed.
    ///
    /// Incremented each time the user taps "Not now", "Dismiss", or similar actions.
    /// Used by the behaviour engine to:
    /// - Reduce resurfacing frequency for repeatedly dismissed items.
    /// - Eventually stop showing items that have been dismissed many times.
    ///
    /// **Edge Case**: Can remain at `0` even if `state == .dismissed` if the
    /// item was dismissed via an alternative mechanism that didn't increment the counter.
    let timesDismissed: Int
    
    /// Number of times the user has acted on this item (e.g., tapped the primary action).
    ///
    /// "Acting on" an item typically means:
    /// - Tapping to open the URL in Safari.
    /// - Copying the content.
    /// - Any other primary engagement action.
    ///
    /// **Edge Case**: Can remain at `0` even if `state == .acted` in rare cases
    /// (e.g., state was set during migration or via a bulk update).
    let timesActedOn: Int
    
    /// Last time this item appeared in a widget or surfaced view.
    ///
    /// Used by the behaviour engine to:
    /// - Avoid showing the same item too frequently.
    /// - Calculate time-since-last-shown for scoring algorithms.
    ///
    /// **Edge Case**: `nil` for items that have never been surfaced yet.
    /// Fresh items will have `lastShownAt == nil` initially.
    let lastShownAt: Date?
    
    /// Last time the user explicitly acted on this item.
    ///
    /// Distinct from `lastShownAt`: an item can be shown without being acted upon.
    /// Used to track engagement recency.
    ///
    /// **Edge Case**: `nil` for items that have never been acted upon.
    /// Even `.acted` items may have `lastActionAt == nil` if the state was set
    /// without recording a timestamp (e.g., during migration).
    let lastActionAt: Date?
}

// MARK: - StoredItem Helpers

extension StoredItem {
    /// Convenience constructor for creating a new stored item from a capture + classification.
    ///
    /// This helper encapsulates the common pattern of converting a `CaptureEvent`
    /// and `ClassificationResult` into a `StoredItem` ready for persistence.
    ///
    /// **Default Behavior**:
    /// - Uses the capture event's `id` as the stored item's `id`.
    /// - Initializes state to `.fresh` (never acted upon or dismissed).
    /// - Sets all counters and "last action" timestamps to zero/nil.
    /// - Uses `createdAt` from the `now` parameter (defaults to current time).
    ///
    /// - Parameters:
    ///   - event: The original capture event containing raw content and metadata.
    ///   - classification: The classifier's output for the capture.
    ///   - now: The timestamp to use for `createdAt` (defaults to current time).
    ///           This parameter exists primarily for testing and ensuring consistent
    ///           timestamps when processing multiple items in a batch.
    /// - Returns: A new `StoredItem` in `.fresh` state, ready to be saved.
    ///
    /// **Error Handling**: This method never fails. Even if `event.url` or `event.rawText`
    /// are `nil`, a valid `StoredItem` is returned with those fields as `nil`.
    ///
    /// **Note on `textSnippet`**: This uses `event.rawText` directly. In practice,
    /// callers may want to clean, trim, or truncate the text before creating the
    /// `StoredItem`, but that logic is left to the caller (typically the Storage layer).
    static func from(
        event: CaptureEvent,
        classification: ClassificationResult,
        now: Date = Date()
    ) -> StoredItem {
        return StoredItem(
            id: event.id,
            createdAt: now,
            category: classification.category,
            stack: classification.stack,
            triggerType: event.triggerType,
            url: event.url,
            textSnippet: event.rawText, // May be nil; callers can refine if needed
            state: .fresh,
            timesDismissed: 0,
            timesActedOn: 0,
            lastShownAt: nil,
            lastActionAt: nil
        )
    }
}
