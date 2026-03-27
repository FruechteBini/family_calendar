import SwiftUI

struct CategoryPicker: View {
    let categories: [CategoryResponse]
    @Binding var selectedCategoryId: Int?
    var allowNone: Bool = true

    private var selectedCategory: CategoryResponse? {
        categories.first { $0.id == selectedCategoryId }
    }

    var body: some View {
        Menu {
            if allowNone {
                Button {
                    selectedCategoryId = nil
                } label: {
                    if selectedCategoryId == nil {
                        Label("Keine Kategorie", systemImage: "checkmark")
                    } else {
                        Text("Keine Kategorie")
                    }
                }

                Divider()
            }

            ForEach(categories) { category in
                Button {
                    selectedCategoryId = category.id
                } label: {
                    HStack {
                        Text("\(category.icon) \(category.name)")
                        if selectedCategoryId == category.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if let cat = selectedCategory {
                    Circle()
                        .fill(Color(hex: cat.color))
                        .frame(width: 10, height: 10)
                    Text("\(cat.icon) \(cat.name)")
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "tag")
                        .foregroundStyle(.appSecondary)
                    Text("Keine Kategorie")
                        .foregroundStyle(.appSecondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
            )
        }
        .accessibilityLabel("Kategorie: \(selectedCategory?.name ?? "Keine")")
    }
}

#Preview {
    struct Preview: View {
        @State private var selected: Int? = 1
        var body: some View {
            VStack(spacing: 16) {
                CategoryPicker(
                    categories: [
                        .init(id: 1, name: "Arbeit", color: "#0052CC", icon: "💼"),
                        .init(id: 2, name: "Familie", color: "#00875A", icon: "👨‍👩‍👧"),
                        .init(id: 3, name: "Einkauf", color: "#FF8B00", icon: "🛒")
                    ],
                    selectedCategoryId: $selected
                )

                CategoryPicker(
                    categories: [
                        .init(id: 1, name: "Arbeit", color: "#0052CC", icon: "💼"),
                    ],
                    selectedCategoryId: .constant(nil)
                )
            }
            .padding()
        }
    }
    return Preview()
}
