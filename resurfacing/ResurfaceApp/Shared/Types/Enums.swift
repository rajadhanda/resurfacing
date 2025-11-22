import Foundation

// MARK: - ItemCategory

/// Semantic category inferred by the classifier for a captured item.
///
/// This enum represents the content type that the on-device classifier assigns
/// to each captured piece of content. The classifier uses heuristics and/or
/// lightweight ML models to determine the most likely category.
enum ItemCategory: String, Codable, CaseIterable, Equatable, Hashable {
    /// A recipe or cooking-related content (e.g., ingredients, cooking instructions).
    case recipe
    
    /// A workout or exercise-related content (e.g., exercise routines, fitness instructions).
    case workout
    
    /// An inspirational or reflective quote (e.g., wisdom, motivation, thoughts).
    case quote
    
    /// No confident category could be assigned.
    ///
    /// **Important**: This is NOT the same as "missing data" or an error state.
    /// It is a valid classification outcome indicating that the classifier
    /// could not confidently categorize the content into any of the known types.
    /// Items with `.none` may still be stored but are less likely to be surfaced.
    case none
}

// MARK: - StackType

/// High-level "stack" buckets used for behaviour engine theming and organization.
///
/// While `ItemCategory` provides granular semantic classification, `StackType`
/// groups related categories into broader themes for UI presentation and
/// time-based resurfacing logic.
enum StackType: String, Codable, CaseIterable, Equatable, Hashable {
    /// Food-related content (recipes, cooking, meal planning).
    case food
    
    /// Physical activity content (workouts, exercise, movement).
    case body
    
    /// Mental and reflective content (quotes, mindset, wisdom).
    case mind
    
    /// Catch-all for miscellaneous or future content types.
    case other
    
    /// Human-friendly display name for the stack.
    ///
    /// Used in UI elements when presenting the stack to the user.
    var displayName: String {
        switch self {
        case .food:
            return "Food"
        case .body:
            return "Body"
        case .mind:
            return "Mind"
        case .other:
            return "Other"
        }
    }
    
    /// Simple symbolic emoji representation of the stack.
    ///
    /// Provides a quick visual identifier without requiring any UI framework imports.
    /// These are plain String values for maximum portability.
    var emoji: String {
        switch self {
        case .food:
            return "🍽️"
        case .body:
            return "💪"
        case .mind:
            return "🧠"
        case .other:
            return "📦"
        }
    }
}

// MARK: - ItemState

/// Lifecycle state of a stored item from the user's perspective.
///
/// Items progress through these states as users interact with them. This enum
/// captures the high-level engagement status without tracking detailed analytics.
///
/// **State Transitions**:
/// - `.fresh` → `.acted`: User tapped the primary action (opened link, viewed content).
/// - `.fresh` → `.dismissed`: User explicitly tapped "not now" or dismissed.
/// - `.dismissed` → `.acted`: User later engaged with a previously dismissed item.
/// - `.acted` → `.acted`: Repeated engagements don't change state (tracked via counters).
enum ItemState: String, Codable, CaseIterable, Equatable, Hashable {
    /// Item has never been acted upon or dismissed.
    ///
    /// This is the initial state when an item is first stored. Fresh items
    /// are prime candidates for resurfacing by the behaviour engine.
    case fresh
    
    /// User has tapped the primary action at least once.
    ///
    /// This indicates engagement and is tracked separately from the number of times
    /// acted on (via `timesActedOn` counter). Acted items may still be resurfaced
    /// but with lower priority than fresh items.
    case acted
    
    /// User explicitly dismissed or skipped this item.
    ///
    /// Indicates the user chose not to engage at the time of presentation.
    /// Dismissed items can still be resurfaced later (but less frequently)
    /// or can transition to `.acted` if the user later engages.
    case dismissed
}

// MARK: - CaptureTriggerType

/// How the capture was initiated by the user.
///
/// This enum tracks the entry point through which content was saved to the app,
/// which can be useful for analytics, debugging, and understanding user behaviour.
enum CaptureTriggerType: String, Codable, CaseIterable, Equatable, Hashable {
    /// Quick Save initiated via App Shortcut, Back Tap, or keyboard shortcut.
    ///
    /// This represents a direct, fast-path capture mechanism where the user
    /// explicitly invoked a system-level shortcut to save content quickly
    /// without opening the share sheet.
    case quickSave
    
    /// Content shared via iOS Share Extension.
    ///
    /// This is the traditional share sheet flow where users tap the share button
    /// in another app and select this app as the destination.
    case shareExtension
}

// MARK: - TimeBucket

/// Coarse time-of-day buckets for feature extraction and behaviour engine.
///
/// These buckets help the classifier and behaviour engine understand temporal
/// patterns in content capture and optimal resurfacing times.
///
/// **Bucket Boundaries** (based on 24-hour clock):
/// - `.morning`: 5:00 - 11:59
/// - `.afternoon`: 12:00 - 17:59
/// - `.evening`: 18:00 - 21:59
/// - `.night`: 22:00 - 4:59
///
/// **Edge Cases**:
/// - Boundary hours are inclusive of the start time, exclusive of the end.
///   For example, 11:59 AM is `.morning`, but 12:00 PM is `.afternoon`.
/// - Midnight (00:00) through 4:59 AM is classified as `.night`.
enum TimeBucket: String, Codable, CaseIterable, Equatable, Hashable {
    /// Morning hours (5:00 - 11:59).
    case morning
    
    /// Afternoon hours (12:00 - 17:59).
    case afternoon
    
    /// Evening hours (18:00 - 21:59).
    case evening
    
    /// Night hours (22:00 - 4:59).
    case night
    
    /// Determines the time bucket for a given date.
    ///
    /// This is a performant O(1) operation that extracts the hour component
    /// and maps it to the appropriate bucket.
    ///
    /// - Parameters:
    ///   - date: The date/time to classify into a bucket.
    ///   - calendar: The calendar to use for hour extraction (defaults to `.current`).
    /// - Returns: The `TimeBucket` corresponding to the hour of day.
    ///
    /// **Performance**: Uses only hour extraction, no expensive date arithmetic.
    static func bucket(for date: Date, calendar: Calendar = .current) -> TimeBucket {
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            // 5:00 AM - 11:59 AM
            return .morning
        case 12..<18:
            // 12:00 PM - 5:59 PM
            return .afternoon
        case 18..<22:
            // 6:00 PM - 9:59 PM
            return .evening
        default:
            // 10:00 PM - 4:59 AM (wraps around midnight)
            return .night
        }
    }
}

