import SwiftUI

struct BadgeCardView: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let earnedDate: Date?

    private var color: Color {
        guard isEarned else { return .gray }
        switch badgeType.iconColor {
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "pink": return .pink
        case "teal": return .teal
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badgeType.iconName)
                .font(.title)
                .foregroundStyle(color)
                .opacity(isEarned ? 1.0 : 0.3)

            Text(badgeType.displayName)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isEarned ? .primary : .secondary)

            if let earnedDate, isEarned {
                Text(earnedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEarned ? color.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}
