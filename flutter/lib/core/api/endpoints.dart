class Endpoints {
  Endpoints._();

  // Auth
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';
  static const authLinkMember = '/api/auth/link-member';
  static const authFamily = '/api/auth/family';
  static const authFamilyJoin = '/api/auth/family/join';

  // Events
  static const events = '/api/events/';
  static String event(int id) => '/api/events/$id';

  // Todos
  static const todos = '/api/todos/';
  static String todo(int id) => '/api/todos/$id';
  static String todoComplete(int id) => '/api/todos/$id/complete';
  static String todoLinkEvent(int id) => '/api/todos/$id/link-event';
  static String todoProposals(int id) => '/api/todos/$id/proposals';

  // Proposals
  static String proposalRespond(int id) => '/api/proposals/$id/respond';
  static const proposalsPending = '/api/proposals/pending';

  // Recipes
  static const recipes = '/api/recipes/';
  static String recipe(int id) => '/api/recipes/$id';
  static const recipeSuggestions = '/api/recipes/suggestions';
  static const recipeParseUrl = '/api/recipes/parse-url';

  // Meals
  static const mealsPlan = '/api/meals/plan';
  static String mealSlot(String date, String slot) =>
      '/api/meals/plan/$date/$slot';
  static String mealSlotDone(String date, String slot) =>
      '/api/meals/plan/$date/$slot/done';
  static const mealsHistory = '/api/meals/history';

  // Shopping
  static const shoppingList = '/api/shopping/list';
  static const shoppingGenerate = '/api/shopping/generate';
  static const shoppingItems = '/api/shopping/items';
  static String shoppingItemCheck(int id) => '/api/shopping/items/$id/check';
  static String shoppingItemDelete(int id) => '/api/shopping/items/$id';
  static const shoppingSort = '/api/shopping/sort';

  // Pantry
  static const pantry = '/api/pantry/';
  static const pantryBulk = '/api/pantry/bulk';
  static String pantryItem(int id) => '/api/pantry/$id';
  static const pantryAlerts = '/api/pantry/alerts';
  static String pantryAlertAddToShopping(int id) =>
      '/api/pantry/alerts/$id/add-to-shopping';
  static String pantryAlertDismiss(int id) =>
      '/api/pantry/alerts/$id/dismiss';

  // Cookidoo
  static const cookidooStatus = '/api/cookidoo/status';
  static const cookidooCollections = '/api/cookidoo/collections';
  static const cookidooShoppingList = '/api/cookidoo/shopping-list';
  static String cookidooRecipe(String id) => '/api/cookidoo/recipes/$id';
  static String cookidooRecipeImport(String id) =>
      '/api/cookidoo/recipes/$id/import';
  static const cookidooCalendar = '/api/cookidoo/calendar';

  // Knuspr
  static const knusprProductSearch = '/api/knuspr/products/search';
  static const knusprCartAdd = '/api/knuspr/cart/add';
  static String knusprCartSendList(int id) =>
      '/api/knuspr/cart/send-list/$id';
  static const knusprDeliverySlots = '/api/knuspr/delivery-slots';
  static const knusprCart = '/api/knuspr/cart';

  // AI
  static const aiAvailableRecipes = '/api/ai/available-recipes';
  static const aiGenerateMealPlan = '/api/ai/generate-meal-plan';
  static const aiConfirmMealPlan = '/api/ai/confirm-meal-plan';
  static const aiUndoMealPlan = '/api/ai/undo-meal-plan';
  static const aiVoiceCommand = '/api/ai/voice-command';

  // Categories
  static const categories = '/api/categories/';
  static String category(int id) => '/api/categories/$id';

  // Family Members
  static const familyMembers = '/api/family-members/';
  static String familyMember(int id) => '/api/family-members/$id';
}
