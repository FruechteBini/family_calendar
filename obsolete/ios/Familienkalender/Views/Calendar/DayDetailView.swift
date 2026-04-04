import SwiftUI

struct DayDetailView: View {
    @Bindable var viewModel: CalendarViewModel
    @State private var editingEvent: EventResponse?
    @State private var showingNewEvent = false

    private var selectedEvents: [EventResponse] {
        viewModel.eventsForDate(viewModel.selectedDate)
            .sorted { lhs, rhs in
                if lhs.allDay != rhs.allDay { return lhs.allDay }
                return lhs.start < rhs.start
            }
    }

    private var dateHeader: String {
        let date = viewModel.selectedDate
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateHeader)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal)

            if selectedEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(.appSecondary.opacity(0.5))
                    Text("Keine Termine an diesem Tag")
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(selectedEvents) { event in
                        EventRowView(event: event)
                            .onTapGesture {
                                editingEvent = event
                            }
                    }
                }
                .padding(.horizontal)
            }

            Button {
                showingNewEvent = true
            } label: {
                Label("Termin hinzufügen", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .tint(.appPrimary)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(item: $editingEvent) { event in
            EventFormView(
                viewModel: viewModel,
                editingEvent: event
            )
        }
        .sheet(isPresented: $showingNewEvent) {
            EventFormView(
                viewModel: viewModel,
                initialDate: viewModel.selectedDate
            )
        }
    }
}

// MARK: - Event Row

private struct EventRowView: View {
    let event: EventResponse

    private var categoryColor: Color {
        if let cat = event.category {
            return Color(hex: cat.color)
        }
        return .appPrimary
    }

    private var timeText: String {
        if event.allDay { return "Ganztägig" }

        let startTime: String
        let endTime: String

        if let startDate = Date.fromISO(event.start) {
            startTime = startDate.timeString
        } else {
            startTime = String(event.start.suffix(5))
        }

        if let endDate = Date.fromISO(event.end) {
            endTime = endDate.timeString
        } else {
            endTime = String(event.end.suffix(5))
        }

        return "\(startTime) – \(endTime)"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: event.allDay ? "sun.max.fill" : "clock")
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                    Text(timeText)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }

            Spacer()

            if !event.members.isEmpty {
                HStack(spacing: -6) {
                    ForEach(event.members.prefix(4)) { member in
                        Text(member.avatarEmoji)
                            .font(.system(size: 16))
                            .frame(width: 24, height: 24)
                            .background(Color(hex: member.color).opacity(0.3))
                            .clipShape(Circle())
                    }
                    if event.members.count > 4 {
                        Text("+\(event.members.count - 4)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.appSecondary)
                            .frame(width: 24, height: 24)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
