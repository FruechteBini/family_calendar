import Foundation
import Observation

@Observable
final class AppDependencies {
    let keychainManager: KeychainManager
    let apiClient: APIClient
    let authManager: AuthManager

    @ObservationIgnored private var _eventRepository: EventRepository?
    @ObservationIgnored private var _todoRepository: TodoRepository?
    @ObservationIgnored private var _recipeRepository: RecipeRepository?
    @ObservationIgnored private var _mealPlanRepository: MealPlanRepository?
    @ObservationIgnored private var _shoppingRepository: ShoppingRepository?
    @ObservationIgnored private var _pantryRepository: PantryRepository?
    @ObservationIgnored private var _categoryRepository: CategoryRepository?
    @ObservationIgnored private var _memberRepository: FamilyMemberRepository?
    @ObservationIgnored private var _proposalRepository: ProposalRepository?
    @ObservationIgnored private var _aiRepository: AIRepository?
    @ObservationIgnored private var _cookidooRepository: CookidooRepository?

    var eventRepository: EventRepository {
        if _eventRepository == nil { _eventRepository = EventRepository(apiClient: apiClient) }
        return _eventRepository!
    }

    var todoRepository: TodoRepository {
        if _todoRepository == nil { _todoRepository = TodoRepository(apiClient: apiClient) }
        return _todoRepository!
    }

    var recipeRepository: RecipeRepository {
        if _recipeRepository == nil { _recipeRepository = RecipeRepository(apiClient: apiClient) }
        return _recipeRepository!
    }

    var mealPlanRepository: MealPlanRepository {
        if _mealPlanRepository == nil { _mealPlanRepository = MealPlanRepository(apiClient: apiClient) }
        return _mealPlanRepository!
    }

    var shoppingRepository: ShoppingRepository {
        if _shoppingRepository == nil { _shoppingRepository = ShoppingRepository(apiClient: apiClient) }
        return _shoppingRepository!
    }

    var pantryRepository: PantryRepository {
        if _pantryRepository == nil { _pantryRepository = PantryRepository(apiClient: apiClient) }
        return _pantryRepository!
    }

    var categoryRepository: CategoryRepository {
        if _categoryRepository == nil { _categoryRepository = CategoryRepository(apiClient: apiClient) }
        return _categoryRepository!
    }

    var memberRepository: FamilyMemberRepository {
        if _memberRepository == nil { _memberRepository = FamilyMemberRepository(apiClient: apiClient) }
        return _memberRepository!
    }

    var proposalRepository: ProposalRepository {
        if _proposalRepository == nil { _proposalRepository = ProposalRepository(apiClient: apiClient) }
        return _proposalRepository!
    }

    var aiRepository: AIRepository {
        if _aiRepository == nil { _aiRepository = AIRepository(apiClient: apiClient) }
        return _aiRepository!
    }

    var cookidooRepository: CookidooRepository {
        if _cookidooRepository == nil { _cookidooRepository = CookidooRepository(apiClient: apiClient) }
        return _cookidooRepository!
    }

    @MainActor
    init() {
        self.keychainManager = KeychainManager()
        self.apiClient = APIClient(keychainManager: keychainManager)
        self.authManager = AuthManager(apiClient: apiClient, keychainManager: keychainManager)

        let authMgr = authManager
        Task { @MainActor in
            await apiClient.setUnauthorizedHandler {
                Task { @MainActor in
                    authMgr.logout()
                }
            }
        }
    }
}

