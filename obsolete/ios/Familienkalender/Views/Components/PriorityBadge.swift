import SwiftUI

struct PriorityBadge: View {
    let priority: Priority

    private var backgroundColor: Color {
        Color(hex: priority.color)
    }

    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    HStack(spacing: 8) {
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)
    }
    .padding()
}
