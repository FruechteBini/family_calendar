import SwiftUI

struct MoreTabView: View {
    @Environment(AppDependencies.self) private var deps

    @State private var memberVM: MemberViewModel?
    @State private var categoryVM: CategoryViewModel?
    @State private var cookidooVM: CookidooViewModel?
    @State private var recipeVM: RecipeViewModel?
    @State private var mealPlanVM: MealPlanViewModel?
    @State private var proposalVM: ProposalViewModel?

    var body: some View {
        List {
            Section {
                NavigationLink {
                    if let vm = memberVM {
                        MembersListView(viewModel: vm)
                    }
                } label: {
                    Label {
                        Text("Familienmitglieder")
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                }

                NavigationLink {
                    if let vm = categoryVM {
                        CategoriesListView(viewModel: vm)
                    }
                } label: {
                    Label {
                        Text("Kategorien")
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color.appWarning)
                    }
                }
            }

            Section {
                NavigationLink {
                    if let vm = cookidooVM {
                        CookidooBrowserView(viewModel: vm)
                    }
                } label: {
                    Label {
                        Text("Cookidoo Browser")
                    } icon: {
                        Image(systemName: "book.fill")
                            .foregroundStyle(Color.appSuccess)
                    }
                }

                NavigationLink {
                    if let vm = recipeVM {
                        RecipeSuggestionsView(viewModel: vm)
                    }
                } label: {
                    Label {
                        Text("Rezeptvorschlaege")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.appWarning)
                    }
                }

                NavigationLink {
                    if let vm = mealPlanVM {
                        CookingHistoryView(viewModel: vm)
                    }
                } label: {
                    Label {
                        Text("Kochhistorie")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label {
                        Text("Einstellungen")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.gray)
                    }
                }

                NavigationLink {
                    FamilyInfoView()
                } label: {
                    Label {
                        Text("Familie")
                    } icon: {
                        Image(systemName: "house.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
        }
        .navigationTitle("Mehr")
        .onAppear { createViewModels() }
    }

    private func createViewModels() {
        if memberVM == nil {
            memberVM = MemberViewModel(memberRepo: deps.memberRepository)
        }
        if categoryVM == nil {
            categoryVM = CategoryViewModel(categoryRepo: deps.categoryRepository)
        }
        if cookidooVM == nil {
            cookidooVM = CookidooViewModel(cookidooRepo: deps.cookidooRepository)
        }
        if recipeVM == nil {
            recipeVM = RecipeViewModel(recipeRepo: deps.recipeRepository)
        }
        if mealPlanVM == nil {
            mealPlanVM = MealPlanViewModel(mealPlanRepo: deps.mealPlanRepository)
        }
        if proposalVM == nil {
            proposalVM = ProposalViewModel(proposalRepo: deps.proposalRepository)
        }
    }
}
