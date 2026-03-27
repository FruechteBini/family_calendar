import SwiftUI

struct MemberChipView: View {
    let member: FamilyMemberResponse
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    private var isSelectable: Bool { onTap != nil }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color(hex: member.color).opacity(isSelected ? 1.0 : 0.75))
                        .frame(width: 40, height: 40)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.appPrimary, lineWidth: 2.5)
                            .frame(width: 44, height: 44)
                    }

                    Text(member.avatarEmoji)
                        .font(.system(size: 20))
                }
                .animation(.easeInOut(duration: 0.15), value: isSelected)

                Text(member.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.appPrimary : .primary)
                    .lineLimit(1)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
        .disabled(!isSelectable)
        .accessibilityLabel("\(member.name)\(isSelected ? ", ausgewählt" : "")")
        .accessibilityAddTraits(isSelectable ? .isButton : .isStaticText)
    }
}

struct MemberChipRow: View {
    let members: [FamilyMemberResponse]
    @Binding var selectedIds: Set<Int>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(members) { member in
                    MemberChipView(
                        member: member,
                        isSelected: selectedIds.contains(member.id)
                    ) {
                        if selectedIds.contains(member.id) {
                            selectedIds.remove(member.id)
                        } else {
                            selectedIds.insert(member.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview("Display") {
    HStack {
        MemberChipView(member: .init(id: 1, name: "Anna", color: "#DE350B", avatarEmoji: "👩", createdAt: ""))
        MemberChipView(member: .init(id: 2, name: "Max", color: "#0052CC", avatarEmoji: "👦", createdAt: ""))
    }
    .padding()
}

#Preview("Selectable") {
    struct Preview: View {
        @State private var selected: Set<Int> = [1]
        var body: some View {
            MemberChipRow(
                members: [
                    .init(id: 1, name: "Anna", color: "#DE350B", avatarEmoji: "👩", createdAt: ""),
                    .init(id: 2, name: "Max", color: "#0052CC", avatarEmoji: "👦", createdAt: ""),
                    .init(id: 3, name: "Lena", color: "#00875A", avatarEmoji: "👧", createdAt: "")
                ],
                selected: $selected
            )
            .padding()
        }
    }
    return Preview()
}
