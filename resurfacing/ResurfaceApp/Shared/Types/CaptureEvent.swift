import Foundation

/// A single capture attempt initiated by the user (via Quick Save, Share, etc.).
///
/// This is a raw, framework-agnostic model that describes what we know at the moment
/// of capture. It does **not** contain derived features or classification results.
///
/// **Purpose**:
/// - Serves as the input to the feature extraction and classification pipeline.
/// - Captures all available context at the moment of user action.
/// - Remains immutable once created to ensure data integrity.
///
/// **Edge Cases**:
/// - It is valid (though not common) to have a `CaptureEvent` with no `url`,
///   no `rawText`, and no `imageData`. Such events may be dropped by downstream
///   processing if there's insufficient content to classify.
/// - The `imageData` field is intentionally kept optional for MVP; OCR is not
///   run automatically on every capture to preserve performance and battery.
///
/// **Performance**:
/// - This is a simple value type (struct) with no computed properties or heavy logic.
/// - All fields are immutable (`let`) to prevent accidental modifications.
struct CaptureEvent: Codable, Equatable {
    /// Stable identifier for this capture event.
    ///
    /// This UUID is generated at the moment of capture and persists through
    /// the entire processing pipeline. It becomes the `id` of the `StoredItem`.
    let id: UUID
    
    /// When the capture occurred, in device local time.
    ///
    /// This timestamp is used for:
    /// - Feature extraction (time-of-day buckets).
    /// - Sorting and organizing captures chronologically.
    /// - Debugging and analytics.
    let timestamp: Date
    
    /// How the capture was initiated (Quick Save / Share Extension).
    ///
    /// Knowing the trigger type helps understand user behaviour patterns and
    /// can inform future UX improvements.
    let triggerType: CaptureTriggerType
    
    /// Optional bundle identifier of the source app (e.g., "com.apple.mobilesafari").
    ///
    /// When available, this provides valuable context about the origin of the content,
    /// which can improve classification accuracy. For example, content from
    /// "com.myfitnesspal.app" is more likely to be workout-related.
    ///
    /// **Edge Case**: May be `nil` if capture was initiated from a context where
    /// the source app is unknown or unavailable (e.g., certain shortcut invocations).
    let sourceAppBundleId: String?
    
    /// URL of the content, if available (e.g., from a browser or share sheet).
    ///
    /// The URL's domain and path can be powerful signals for classification.
    /// For example, "allrecipes.com" strongly suggests a recipe.
    ///
    /// **Edge Case**: May be `nil` if:
    /// - User saved plain text without a link.
    /// - Captured from a non-web source (e.g., screenshot, note).
    let url: URL?
    
    /// Raw text snippet associated with this capture, if any (e.g., shared text, clipboard).
    ///
    /// This text may come from:
    /// - Selected/shared text from another app.
    /// - Clipboard contents at time of Quick Save.
    /// - OCR results if image data was processed (in future iterations).
    ///
    /// **Important**: This field may be empty but is never `nil` once processed
    /// into a `FeatureVector` (downstream code normalizes to empty string if needed).
    ///
    /// **Edge Case**: Can be `nil` if no text was available at capture time.
    let rawText: String?
    
    /// Binary image data associated with this capture, if present (e.g., from a screenshot).
    ///
    /// **MVP Behaviour**: For the initial version, this field is kept optional and
    /// OCR is **not** run automatically. Images are stored but not immediately processed.
    /// Future iterations may add on-demand or background OCR processing.
    ///
    /// **Performance Note**: Large images should ideally be compressed or resized
    /// before storage, but that optimization happens in the capture layer, not here.
    let imageData: Data?
    
    /// Convenience initializer for creating a `CaptureEvent` with sensible defaults.
    ///
    /// This initializer automatically generates a UUID and uses the current timestamp,
    /// making it easy to create events in capture code without boilerplate.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID).
    ///   - timestamp: When the capture occurred (defaults to current time).
    ///   - triggerType: How the capture was initiated (required).
    ///   - sourceAppBundleId: Bundle ID of the source app (optional).
    ///   - url: URL of the captured content (optional).
    ///   - rawText: Text snippet associated with the capture (optional).
    ///   - imageData: Binary image data if available (optional).
    ///
    /// **Error Handling**: This initializer never fails. All optional fields
    /// are safely handled as `nil` if not provided.
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        triggerType: CaptureTriggerType,
        sourceAppBundleId: String? = nil,
        url: URL? = nil,
        rawText: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.triggerType = triggerType
        self.sourceAppBundleId = sourceAppBundleId
        self.url = url
        self.rawText = rawText
        self.imageData = imageData
    }
}

