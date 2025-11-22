import SwiftUI

/// Simple row component for displaying a `StoredItem` in a list.
struct ItemRowView: View {
    let item: StoredItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.stack.emoji)
                Text(item.textSnippet ?? item.url?.host ?? "Unknown Item")
                    .font(.headline)
                    .lineLimit(1)
            }
            
            HStack {
                Badge(text: item.category.rawValue)
                Badge(text: item.state.rawValue, color: stateColor)
                Spacer()
                Text(dateString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Acted: \(item.timesActedOn)")
                Text("Dismissed: \(item.timesDismissed)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    var stateColor: Color {
        switch item.state {
        case .fresh: return .blue
        case .acted: return .green
        case .dismissed: return .gray
        }
    }
    
    var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
}

/// Helper view for displaying small tag badges.
struct Badge: View {
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

