import SwiftUI

struct WeekPlanView: View {
    let mealPlanVM: MealPlanViewModel
    let aiVM: AIMealPlanViewModel
    let shoppingVM: ShoppingViewModel
    let recipeVM: RecipeViewModel

    @State private var showAIWizard = false
    @State private var showHistory = false
    @State private var assignSlotContext: SlotContext?
    @State private var markCookedContext: CookedContext?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success

    struct SlotContext: Identifiable {
        let id = UUID()
        let date: String
        let slot: String
    }

    struct CookedContext: Identifiable {
        let id = UUID()
        let date: String
        let slot: String
        let mealSlot: MealSlotResponse
    }

    // MARK: - Computed

    private var calendarWeek: Int {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        return cal.component(.weekOfYear, from: mealPlanVM.currentWeekStart)
    }

    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM"
        let start = mealPlanVM.currentWeekStart
        let end = start.adding(days: 6)
        let yearFmt = DateFormatter()
        yearFmt.dateFormat = "yyyy"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end)) \(yearFmt.string(from: end))"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    weekHeader

                    if let errorMsg = mealPlanVM.errorMessage {
                        errorBanner(errorMsg)
                    }

                    daysList
                }
                .padding(.bottom, mealPlanVM.undoMealIds != nil ? 100 : 20)
            }
            .refreshable { await mealPlanVM.loadWeek() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let h = abs(value.translation.width)
                        let v = abs(value.translation.height)
                        guard h > v, h > 60 else { return }
                        let direction = value.translation.width < 0 ? 1 : -1
                        mealPlanVM.navigateWeek(by: direction)
                        Task { await mealPlanVM.loadWeek() }
                    }
            )

            if mealPlanVM.undoMealIds != nil {
                UndoBarView(viewModel: mealPlanVM)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: mealPlanVM.undoMealIds != nil)
        .navigationTitle("Wochenplan")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await shoppingVM.generate(weekStart: mealPlanVM.currentWeekStart.isoDateString)
                        if shoppingVM.errorMessage == nil {
                            toastMessage = "Einkaufsliste generiert"
                            toastType = .success
                            showToast = true
                        }
                    }
                } label: {
                    Image(systemName: "cart.badge.plus")
                }

                Button { showAIWizard = true } label: {
                    Image(systemName: "sparkles")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button { showHistory = true } label: {
                    Label("Kochhistorie", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showAIWizard) {
            Task { await mealPlanVM.loadWeek() }
        } content: {
            AIMealPlanWizard(
                viewModel: aiVM,
                mealPlanVM: mealPlanVM,
                weekStart: mealPlanVM.currentWeekStart.isoDateString
            )
            .presentationDetents([.large])
        }
        .sheet(item: $assignSlotContext) { ctx in
            AssignSlotView(
                date: ctx.date,
                slot: ctx.slot,
                mealPlanVM: mealPlanVM,
                recipeVM: recipeVM
            )
            .presentationDetents([.large])
        }
        .sheet(item: $markCookedContext) { ctx in
            MarkCookedSheet(
                date: ctx.date,
                slot: ctx.slot,
                mealSlot: ctx.mealSlot,
                viewModel: mealPlanVM
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                CookingHistoryView(viewModel: mealPlanVM)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Schließen") { showHistory = false }
                        }
                    }
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .loadingOverlay(isLoading: mealPlanVM.isLoading)
        .task { await mealPlanVM.loadWeek() }
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    mealPlanVM.navigateWeek(by: -1)
                    Task { await mealPlanVM.loadWeek() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.appPrimary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("KW \(calendarWeek)")
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    mealPlanVM.navigateWeek(by: 1)
                    Task { await mealPlanVM.loadWeek() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.appPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Text(dateRangeString)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.appDanger)
            Text(message)
                .font(.caption)
                .foregroundStyle(.appDanger)
            Spacer()
        }
        .padding(12)
        .background(Color.appDanger.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Days List

    @ViewBuilder
    private var daysList: some View {
        if let days = mealPlanVM.weekPlan?.days {
            LazyVStack(spacing: 12) {
                ForEach(days) { day in
                    dayRow(day)
                }
            }
            .padding(.horizontal, 16)
        } else if !mealPlanVM.isLoading {
            EmptyStateView(
                icon: "calendar.badge.exclamationmark",
                title: "Kein Wochenplan",
                subtitle: "Der Wochenplan konnte nicht geladen werden. Ziehe nach unten zum Aktualisieren."
            )
        }
    }

    // MARK: - Day Row

    private func dayRow(_ day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayHeaderText(day))
                    .font(.headline)
                    .foregroundStyle(isToday(day.date) ? .appPrimary : .primary)

                if isToday(day.date) {
                    Text("Heute")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.appPrimary, in: Capsule())
                }

                Spacer()
            }

            HStack(spacing: 10) {
                SlotCellView(
                    label: "Mittag",
                    icon: "sun.max.fill",
                    slot: day.lunch,
                    onAssign: { assignSlotContext = SlotContext(date: day.date, slot: "lunch") },
                    onMarkCooked: {
                        if let lunch = day.lunch {
                            markCookedContext = CookedContext(date: day.date, slot: "lunch", mealSlot: lunch)
                        }
                    },
                    onClear: {
                        Task { await mealPlanVM.clearSlot(date: day.date, slot: "lunch") }
                    }
                )

                SlotCellView(
                    label: "Abend",
                    icon: "moon.fill",
                    slot: day.dinner,
                    onAssign: { assignSlotContext = SlotContext(date: day.date, slot: "dinner") },
                    onMarkCooked: {
                        if let dinner = day.dinner {
                            markCookedContext = CookedContext(date: day.date, slot: "dinner", mealSlot: dinner)
                        }
                    },
                    onClear: {
                        Task { await mealPlanVM.clearSlot(date: day.date, slot: "dinner") }
                    }
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: isToday(day.date) ? .appPrimary.opacity(0.15) : .clear, radius: 6, y: 2)
        )
        .overlay(
            isToday(day.date)
                ? RoundedRectangle(cornerRadius: 14).strokeBorder(.appPrimary.opacity(0.3), lineWidth: 1.5)
                : nil
        )
    }

    // MARK: - Helpers

    private func dayHeaderText(_ day: DayPlan) -> String {
        guard let date = Date.fromISODate(day.date) else { return day.weekday }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, dd.MM."
        return formatter.string(from: date)
    }

    private func isToday(_ dateString: String) -> Bool {
        dateString == Date().isoDateString
    }
}
