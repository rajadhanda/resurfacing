import Foundation

/// The brain of the app: determines which item to show next.
///
/// **Purpose**:
/// - Implements the scoring logic to rank `StoredItem`s for a given context.
/// - Pure logic component: takes inputs (items, context), returns output (best item).
/// - Stateless: does not store the items itself, relies on StorageManager to provide them.
struct BehaviourEngine {
    
    // MARK: - Scoring Constants
    
    // These could be tweaked or moved to a configuration file later.
    private let baseScore: Double = 100.0
    private let freshnessBoostMax: Double = 50.0
    private let freshnessDuration: TimeInterval = 7 * 86400 // 7 days considered "fresh"
    
    private let recentShownPenalty: Double = 1000.0 // Huge penalty to prevent spamming
    private let recentShownThreshold: TimeInterval = 24 * 3600 // 24 hours
    
    private let dismissalPenalty: Double = 30.0 // Per dismissal
    private let actionBoost: Double = 10.0 // Per action
    
    // MARK: - API
    
    /// Selects the best item to surface for a specific stack.
    ///
    /// - Parameters:
    ///   - stack: The target stack (Food, Body, Mind, etc.).
    ///   - date: The current date (reference for time-decay calculations).
    ///   - items: The pool of items to choose from.
    /// - Returns: The highest scoring item, or nil if no suitable item is found.
    func bestItem(
        for stack: StackType,
        at date: Date,
        from items: [StoredItem]
    ) -> StoredItem? {
        
        // 1. Filter candidates for the requested stack
        let candidates = items.filter { $0.stack == stack }
        
        guard !candidates.isEmpty else {
            return nil
        }
        
        // 2. Score each candidate
        // We map to a tuple (item, score) so we can debug/sort if needed.
        let scoredCandidates = candidates.map { item -> (StoredItem, Double) in
            let score = calculateScore(for: item, at: date)
            return (item, score)
        }
        
        // 3. Find the max score
        // In a real app, we might want some randomness or a threshold,
        // but for now, we strictly pick the top scorer.
        let best = scoredCandidates.max { $0.1 < $1.1 }
        
        // Optional: Print scores for debugging
        print("--- Behaviour Engine: \(stack.displayName) ---")
        for (item, score) in scoredCandidates.sorted(by: { $0.1 > $1.1 }) {
            print("[\(score)] \(item.textSnippet ?? "Untitled") (State: \(item.state))")
        }
        
        return best?.0
    }
    
    // MARK: - Scoring Logic
    
    /// Calculates a resurfacing score for a single item.
    /// Higher is better.
    private func calculateScore(for item: StoredItem, at now: Date) -> Double {
        var score = baseScore
        
        // 1. Freshness Boost
        // Newer items get a boost, decaying linearly over 'freshnessDuration'.
        let age = now.timeIntervalSince(item.createdAt)
        if age < freshnessDuration {
            let freshnessFactor = 1.0 - (age / freshnessDuration)
            score += freshnessBoostMax * max(0.0, freshnessFactor)
        }
        
        // 2. Penalty for recently shown
        // If it was shown very recently, we really don't want to see it again immediately.
        if let lastShown = item.lastShownAt {
            let timeSinceShown = now.timeIntervalSince(lastShown)
            if timeSinceShown < recentShownThreshold {
                // Apply massive penalty
                score -= recentShownPenalty
            }
        }
        
        // 3. Penalty for dismissals
        // If user kept saying "not now", lower the priority.
        score -= Double(item.timesDismissed) * dismissalPenalty
        
        // 4. Boost for engagement
        // If user has acted on it before, they might like it, so slight boost (or maybe penalty if we want variety?
        // For now, let's assume re-surfacing useful stuff is good, but maybe with diminishing returns).
        // Let's just do a simple linear boost for now.
        score += Double(item.timesActedOn) * actionBoost
        
        // 5. State adjustments
        switch item.state {
        case .dismissed:
            // Additional penalty for being in a dismissed state generally
            score -= 20.0
        case .acted:
            // Neutral or slight boost
            break
        case .fresh:
            // Base state, no adjustment
            break
        }
        
        return score
    }
}

