// Central re-export of all providers for convenience.
// Each repository/feature exposes its own provider in its data/ folder.
// This file serves as an import aggregator.

export '../core/api/api_client.dart';
export '../core/auth/auth_provider.dart';
export '../features/calendar/data/event_repository.dart';
export '../features/todos/data/todo_repository.dart';
export '../features/members/data/member_repository.dart';
export '../features/categories/data/category_repository.dart';
export '../features/recipes/data/recipe_repository.dart';
export '../features/meals/data/meal_repository.dart';
export '../features/shopping/data/shopping_repository.dart';
export '../features/pantry/data/pantry_repository.dart';
export '../features/ai/data/ai_repository.dart';
export '../features/cookidoo/data/cookidoo_repository.dart';
export '../features/knuspr/data/knuspr_repository.dart';
export '../features/knuspr/data/knuspr_status_provider.dart';
