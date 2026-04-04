import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private var backgroundColor: Color {
        Color(hex: difficulty.color)
    }

    var body: some View {
        Text(difficulty.displayName)
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
        DifficultyBadge(difficulty: .easy)
        DifficultyBadge(difficulty: .medium)
        DifficultyBadge(difficulty: .hard)
    }
    .padding()
}
