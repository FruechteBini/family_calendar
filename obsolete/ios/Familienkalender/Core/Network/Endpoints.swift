import Foundation

enum Endpoints {
    enum Auth {
        static let register = "/api/auth/register"
        static let login = "/api/auth/login"
        static let me = "/api/auth/me"
        static let linkMember = "/api/auth/link-member"
        static let family = "/api/auth/family"
        static let familyJoin = "/api/auth/family/join"
    }

    enum Events {
        static let base = "/api/events"
    }

    enum Todos {
        static let base = "/api/todos"
    }

    enum Proposals {
        static let base = "/api/proposals"
    }

    enum Recipes {
        static let base = "/api/recipes"
    }

    enum Meals {
        static let base = "/api/meals"
    }

    enum Shopping {
        static let base = "/api/shopping"
    }

    enum Pantry {
        static let base = "/api/pantry"
    }

    enum AI {
        static let base = "/api/ai"
    }

    enum Categories {
        static let base = "/api/categories"
    }

    enum FamilyMembers {
        static let base = "/api/family-members"
    }

    enum Cookidoo {
        static let base = "/api/cookidoo"
    }

    enum Knuspr {
        static let base = "/api/knuspr"
    }
}
