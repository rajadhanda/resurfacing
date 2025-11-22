import Foundation

/// A processed feature representation derived from a `CaptureEvent`,
/// suitable as input to a lightweight on-device classifier.
///
/// **Purpose**:
/// - Transforms raw capture data into structured features for classification.
/// - Provides a consistent, framework-agnostic interface for ML models and heuristics.
/// - Keeps features simple and performant for on-device processing.
///
/// **Data Flow**:
/// `CaptureEvent` → [FeatureExtractor] → `FeatureVector` → [Classifier] → `ClassificationResult`
///
/// **Design Philosophy**:
/// - This struct contains **derived data only**; no business logic lives here.
/// - All feature extraction logic belongs in the `FeatureExtractor` service.
/// - Features are chosen to be cheap to compute and effective for classification.
///
/// **Performance Considerations**:
/// - `textSnippet` should be kept reasonably short (e.g., first 500-1000 chars)
///   to avoid performance issues in downstream processing. This truncation
///   happens in the `FeatureExtractor`, not here.
/// - Heuristic flags (`hasUnitsLikeGrams`, etc.) are pre-computed booleans
///   to avoid repeated string scanning during classification.
struct FeatureVector: Codable, Equatable {
    /// Domain extracted from URL, e.g., "tiktok.com" or "allrecipes.com".
    ///
    /// The domain (without scheme or path) is a powerful classification signal.
    /// For example:
    /// - "allrecipes.com" → likely a recipe
    /// - "myfitnesspal.com" → likely workout-related
    /// - "goodreads.com" → possibly a quote
    ///
    /// **Edge Case**: May be `nil` if:
    /// - No URL was available in the original `CaptureEvent`.
    /// - URL was malformed or couldn't be parsed.
    let domain: String?
    
    /// Bundle identifier of the source app, if known.
    ///
    /// Carried forward from the `CaptureEvent` for use as a classification feature.
    /// Some apps are strong indicators of content type (e.g., fitness apps,
    /// recipe apps, reading apps).
    ///
    /// **Edge Case**: May be `nil` if source app was unknown at capture time.
    let sourceAppBundleId: String?
    
    /// Coarse time-of-day bucket for when the capture occurred.
    ///
    /// Temporal context can improve classification and resurfacing:
    /// - Recipes often captured in the evening (dinner planning).
    /// - Workouts often captured in the morning or afternoon.
    /// - Quotes may be captured any time but often in the morning.
    ///
    /// This field is **never optional** because every `CaptureEvent` has a timestamp.
    let timeBucket: TimeBucket
    
    /// Day of week as an integer (1...7).
    ///
    /// Provides additional temporal context for classification and behaviour patterns.
    ///
    /// **Important**: The exact convention (e.g., 1 = Sunday vs. 1 = Monday) is
    /// determined by the `FeatureExtractor` based on the `Calendar` used.
    /// Typically follows Foundation's convention where 1 = Sunday, 7 = Saturday.
    ///
    /// **Range**: Always in the range 1...7 (no validation needed here).
    let dayOfWeek: Int
    
    /// Short text snippet (from rawText and/or OCR) used for keyword- and model-based classification.
    ///
    /// This is a cleaned, trimmed, and reasonably short string extracted from:
    /// - The `rawText` field of the `CaptureEvent`.
    /// - Potentially OCR results if image processing was performed.
    ///
    /// **Performance Expectation**:
    /// - Should be trimmed to a reasonable length (e.g., first 500-1000 characters).
    /// - Should not contain excessive whitespace or formatting artifacts.
    /// - If no text is available, this should be an empty string `""` (not `nil`).
    ///
    /// **Edge Case**: Downstream classifiers must handle empty strings gracefully.
    /// An empty string with all heuristic flags set to `false` typically results
    /// in a `.none` category classification.
    let textSnippet: String
    
    /// Heuristic flag: presence of units like "g", "kg", "ml", "cup", "tbsp", etc.
    ///
    /// This boolean indicates whether the text contains measurement units commonly
    /// found in recipes. It's a fast heuristic that improves recipe detection
    /// without requiring heavy NLP processing.
    ///
    /// **Examples**:
    /// - "2 cups flour" → `true`
    /// - "500g chicken breast" → `true`
    /// - "Do 10 reps" → `false`
    let hasUnitsLikeGrams: Bool
    
    /// Heuristic flag: presence of workout markers like "reps", "sets", "kg", "lbs".
    ///
    /// Indicates whether the text contains terminology commonly associated with
    /// exercise and fitness content. Useful for quickly identifying workout-related
    /// captures without deep analysis.
    ///
    /// **Examples**:
    /// - "3 sets of 10 reps" → `true`
    /// - "Bench press 80kg" → `true`
    /// - "Mix ingredients together" → `false`
    let hasWorkoutMarkers: Bool
    
    /// Heuristic flag: presence of quote markers (quotes, em dash with author, etc.).
    ///
    /// Detects formatting patterns typical of inspirational quotes, such as:
    /// - Text enclosed in quotation marks.
    /// - Em dash followed by a name (author attribution).
    /// - Other quote-specific patterns.
    ///
    /// **Examples**:
    /// - "Be the change you wish to see" — Gandhi → `true`
    /// - "'Success is not final' - Churchill" → `true`
    /// - "Here's a great recipe for pasta" → `false`
    let hasQuoteMarkers: Bool
    
    /// Heuristic flag: presence of reading markers (e.g., "article", "newsletter", "today's news").
    ///
    /// Detects terminology and patterns commonly associated with news articles,
    /// blog posts, newsletters, and long-form reading content. This helps the
    /// classifier identify reading-related captures without requiring deep NLP.
    ///
    /// **Examples**:
    /// - "Read this article about..." → `true`
    /// - "Today's newsletter" → `true`
    /// - "Breaking news: ..." → `true`
    /// - "Check out this recipe" → `false`
    ///
    /// **Note**: This flag is planned for future use in the classifier. Even if
    /// not fully utilized in MVP, having it in the feature vector prepares the
    /// system for more sophisticated reading content detection.
    let hasReadingMarkers: Bool
}

