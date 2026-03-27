import SwiftUI

struct MainTabView: View {
    @Environment(AppDependencies.self) private var deps

    @State private var calendarVM: CalendarViewModel?
    @State private var todoVM: TodoViewModel?
    @State private var recipeVM: RecipeViewModel?
    @State private var mealPlanVM: MealPlanViewModel?
    @State private var shoppingVM: ShoppingViewModel?
    @State private var pantryVM: PantryViewModel?
    @State private var voiceVM: VoiceCommandViewModel?
    @State private var proposalVM: ProposalViewModel?

    @State private var showVoiceSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                NavigationStack {
                    if let vm = calendarVM {
                        CalendarView(viewModel: vm)
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("Kalender", systemImage: "calendar.fill")
                }

                NavigationStack {
                    if let vm = todoVM {
                        TodoListView(viewModel: vm)
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle.fill")
                }

                NavigationStack {
                    MealsContainerView(
                        mealPlanVM: mealPlanVM,
                        recipeVM: recipeVM,
                        shoppingVM: shoppingVM
                    )
                }
                .tabItem {
                    Label("Essen", systemImage: "fork.knife")
                }

                NavigationStack {
                    ShoppingContainerView(
                        shoppingVM: shoppingVM,
                        pantryVM: pantryVM,
                        mealPlanVM: mealPlanVM
                    )
                }
                .tabItem {
                    Label("Einkauf", systemImage: "cart.fill")
                }

                NavigationStack {
                    MoreTabView()
                }
                .tabItem {
                    Label("Mehr", systemImage: "ellipsis.circle.fill")
                }
            }
            .tint(Color.appPrimary)

            voiceFAB
        }
        .onAppear { createViewModels() }
    }

    private func createViewModels() {
        if calendarVM == nil {
            calendarVM = CalendarViewModel(
                eventRepo: deps.eventRepository,
                categoryRepo: deps.categoryRepository,
                memberRepo: deps.memberRepository
            )
        }
        if todoVM == nil {
            todoVM = TodoViewModel(
                todoRepo: deps.todoRepository,
                categoryRepo: deps.categoryRepository,
                memberRepo: deps.memberRepository
            )
        }
        if recipeVM == nil {
            recipeVM = RecipeViewModel(recipeRepo: deps.recipeRepository)
        }
        if mealPlanVM == nil {
            mealPlanVM = MealPlanViewModel(mealPlanRepo: deps.mealPlanRepository)
        }
        if shoppingVM == nil {
            shoppingVM = ShoppingViewModel(shoppingRepo: deps.shoppingRepository)
        }
        if pantryVM == nil {
            pantryVM = PantryViewModel(pantryRepo: deps.pantryRepository)
        }
        if proposalVM == nil {
            proposalVM = ProposalViewModel(proposalRepo: deps.proposalRepository)
        }
        if voiceVM == nil {
            voiceVM = VoiceCommandViewModel(aiRepo: deps.aiRepository)
        }
    }

    @ViewBuilder
    private var voiceFAB: some View {
        if let vm = voiceVM {
            Button {
                showVoiceSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(vm.isListening ? Color.appDanger : Color.appPrimary)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

                    if vm.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: vm.isListening ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(vm.isProcessing)
            .padding(.trailing, 20)
            .padding(.bottom, 90)
            .sheet(isPresented: $showVoiceSheet) {
                VoiceResultSheet(viewModel: vm)
            }
        }
    }
}

// MARK: - Meals Container (Segmented: Wochenplan / Rezepte)

struct MealsContainerView: View {
    @Environment(AppDependencies.self) private var deps

    let mealPlanVM: MealPlanViewModel?
    let recipeVM: RecipeViewModel?
    let shoppingVM: ShoppingViewModel?

    enum MealsTab: String, CaseIterable {
        case weekPlan = "Wochenplan"
        case recipes = "Rezepte"
    }

    @State private var selectedTab: MealsTab = .weekPlan

    var body: some View {
        VStack(spacing: 0) {
            Picker("Bereich", selection: $selectedTab) {
                ForEach(MealsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .weekPlan:
                if let mpVM = mealPlanVM, let rVM = recipeVM, let sVM = shoppingVM {
                    let aiVM = AIMealPlanViewModel(aiRepo: deps.aiRepository)
                    WeekPlanView(mealPlanVM: mpVM, aiVM: aiVM, shoppingVM: sVM, recipeVM: rVM)
                } else {
                    ProgressView()
                }
            case .recipes:
                if let vm = recipeVM {
                    RecipeListView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Essen")
    }
}

// MARK: - Shopping Container (Segmented: Einkaufsliste / Vorratskammer)

struct ShoppingContainerView: View {
    let shoppingVM: ShoppingViewModel?
    let pantryVM: PantryViewModel?
    let mealPlanVM: MealPlanViewModel?

    enum ShoppingTab: String, CaseIterable {
        case shopping = "Einkaufsliste"
        case pantry = "Vorratskammer"
    }

    @State private var selectedTab: ShoppingTab = .shopping

    var body: some View {
        VStack(spacing: 0) {
            Picker("Bereich", selection: $selectedTab) {
                ForEach(ShoppingTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .shopping:
                if let vm = shoppingVM {
                    ShoppingListView(
                        viewModel: vm,
                        weekStart: mealPlanVM?.currentWeekStart.isoDateString ?? Date().mondayOfWeek.isoDateString
                    )
                } else {
                    ProgressView()
                }
            case .pantry:
                if let vm = pantryVM {
                    PantryView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Einkauf")
    }
}
