import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    @State private var showingNewEvent = false

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.currentMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MonthGridView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal)

                    DayDetailView(viewModel: viewModel)
                        .padding(.top, 8)
                }
            }
            .refreshable {
                await viewModel.loadEvents()
            }
            .navigationTitle(monthYearTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        viewModel.navigateMonth(by: -1)
                        Task { await viewModel.loadEvents() }
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Button {
                        viewModel.navigateMonth(by: 1)
                        Task { await viewModel.loadEvents() }
                    } label: {
                        Image(systemName: "chevron.right")
                    }

                    Button("Heute") {
                        viewModel.currentMonth = Date()
                        viewModel.selectedDate = Date()
                        Task { await viewModel.loadEvents() }
                    }
                    .font(.subheadline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEvent) {
                EventFormView(
                    viewModel: viewModel,
                    initialDate: viewModel.selectedDate
                )
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.appDanger, in: RoundedRectangle(cornerRadius: 10))
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: viewModel.errorMessage)
                    .onTapGesture { viewModel.errorMessage = nil }
                }
            }
            .loadingOverlay(isLoading: viewModel.isLoading, message: "Termine laden…")
            .task {
                async let events: () = viewModel.loadEvents()
                async let shared: () = viewModel.loadSharedData()
                _ = await (events, shared)
            }
        }
    }
}
