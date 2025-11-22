import Foundation

/// Output of the on-device classifier given a `FeatureVector`.
///
/// **Purpose**:
/// - Represents the classifier's prediction about the content type.
/// - Combines semantic category, high-level stack, and confidence score.
/// - Provides a clean interface between the classification layer and storage/UI.
///
/// **Data Flow**:
/// `FeatureVector` → [Classifier] → `ClassificationResult` → [Storage/UI]
///
/// **Confidence Interpretation**:
/// - `0.0`: No confidence (should not occur in practice).
/// - `0.0 - 0.5`: Low confidence; may indicate `.none` category or uncertain classification.
/// - `0.5 - 0.7`: Moderate confidence; often actionable but may need manual review.
/// - `0.7 - 1.0`: High confidence; strongly suggests the predicted category is correct.
///
/// **Edge Cases**:
/// - Higher layers (e.g., storage manager, behaviour engine) may treat low-confidence
///   results (e.g., confidence < 0.5) as non-actionable and choose not to store or
///   surface them.
/// - A confidence of `1.0` does not guarantee correctness, just high certainty
///   from the model/heuristics.
struct ClassificationResult: Codable, Equatable {
    /// Semantic category predicted for this capture (recipe, workout, quote, none).
    ///
    /// This is the primary classification output. If the classifier cannot
    /// confidently assign a specific category, it will use `.none`.
    let category: ItemCategory
    
    /// High-level stack bucket derived from the category (food, body, mind, other).
    ///
    /// The stack provides a coarser grouping for UI theming and behaviour engine
    /// logic. It's typically derived deterministically from the category:
    /// - `.recipe` → `.food`
    /// - `.workout` → `.body`
    /// - `.quote` → `.mind`
    /// - `.none` → `.other`
    ///
    /// **Note**: In the current design, stack is explicitly provided by the classifier
    /// rather than computed from category. This allows for future flexibility if
    /// we want to introduce categories that could map to multiple stacks contextually.
    let stack: StackType
    
    /// Confidence score in the range [0.0, 1.0].
    ///
    /// Higher values indicate more confident predictions. This score may come from:
    /// - ML model probability outputs.
    /// - Heuristic scoring based on feature matches.
    /// - A combination of both.
    ///
    /// **Clamping**: The initializer ensures this value is always within [0, 1]
    /// to prevent downstream bugs if a model or heuristic produces out-of-range values.
    let confidence: Double
    
    /// Internal initializer that clamps the confidence into [0.0, 1.0] to avoid invalid values.
    ///
    /// This defensive measure ensures that even if a classifier or heuristic
    /// produces an out-of-range confidence value (due to bugs, numerical issues,
    /// or incorrect logic), the `ClassificationResult` will always be valid.
    ///
    /// - Parameters:
    ///   - category: The predicted semantic category.
    ///   - stack: The high-level stack bucket corresponding to the category.
    ///   - confidence: Raw confidence score (will be clamped to [0, 1]).
    ///
    /// **Error Handling**: This initializer never fails. Out-of-range confidence
    /// values are silently clamped rather than causing a crash or error.
    ///
    /// **Performance**: Clamping is O(1) with minimal overhead (two simple comparisons).
    init(category: ItemCategory, stack: StackType, confidence: Double) {
        self.category = category
        self.stack = stack
        // Clamp to [0, 1] as a defensive measure against buggy classifiers.
        // max(0.0, x) ensures x >= 0, then min(1.0, x) ensures x <= 1.
        self.confidence = min(max(confidence, 0.0), 1.0)
    }
}

