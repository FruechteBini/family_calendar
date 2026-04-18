class Endpoints {
  Endpoints._();

  // Auth
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';
  static const authPreferences = '/api/auth/preferences';
  static const authLinkMember = '/api/auth/link-member';
  static const authFamily = '/api/auth/family';
  static const authFamilyJoin = '/api/auth/family/join';
  static const authGoogle = '/api/auth/google';
  static const authGoogleLink = '/api/auth/google/link';
  static const authGoogleUnlink = '/api/auth/google/unlink';
  static const authGoogleGrantSync = '/api/auth/google/grant-sync';

  // Google sync
  static const googleSyncStatus = '/api/google-sync/status';
  static const googleSyncSettings = '/api/google-sync/settings';
  static const googleSyncTrigger = '/api/google-sync/trigger';

  // Events
  static const events = '/api/events/';
  static String event(int id) => '/api/events/$id';

  // Notifications
  static const notificationsLevels = '/api/notifications/levels';
  static String notificationsLevel(int id) => '/api/notifications/levels/$id';
  static const notificationsLevelsReorder = '/api/notifications/levels/reorder';
  static const notificationsPreferences = '/api/notifications/preferences';

  // Todos
  static const todos = '/api/todos/';
  static String todo(int id) => '/api/todos/$id';
  static String todoComplete(int id) => '/api/todos/$id/complete';
  static String todoReorderSubtodos(int id) =>
      '/api/todos/$id/reorder-subtodos';
  static String todoLinkEvent(int id) => '/api/todos/$id/link-event';
  static String todoProposals(int id) => '/api/todos/$id/proposals';
  static String todoAttachments(int id) => '/api/todos/$id/attachments';
  static String todoAttachment(int todoId, int attId) =>
      '/api/todos/$todoId/attachments/$attId';
  static String todoAttachmentDownload(int todoId, int attId) =>
      '/api/todos/$todoId/attachments/$attId/download';

  // Proposals
  static String proposalRespond(int id) => '/api/proposals/$id/respond';
  static const proposalsPending = '/api/proposals/pending';

  // Recipes
  static const recipes = '/api/recipes/';
  static String recipe(int id) => '/api/recipes/$id';
  static String recipeImage(int id) => '/api/recipes/$id/image';
  static const recipeSuggestions = '/api/recipes/suggestions';
  static const recipeParseUrl = '/api/recipes/parse-url';

  // Recipe categories & tags (separate from todo categories)
  static const recipeCategories = '/api/recipe-categories/';
  static String recipeCategory(int id) => '/api/recipe-categories/$id';
  static const recipeCategoriesReorder = '/api/recipe-categories/reorder';
  static const recipeTags = '/api/recipe-tags/';
  static String recipeTag(int id) => '/api/recipe-tags/$id';

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
  static const shoppingClearAll = '/api/shopping/clear-all';

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
  static const cookidooPlanDay = '/api/cookidoo/plan-day';
  static const cookidooCalendar = '/api/cookidoo/calendar';

  // Knuspr
  static const knusprStatus = '/api/knuspr/status';
  static const knusprProductSearch = '/api/knuspr/products/search';
  static const knusprCartAdd = '/api/knuspr/cart/add';
  static String knusprCartSendList(int id) =>
      '/api/knuspr/cart/send-list/$id';
  static String knusprPreviewList(int id) =>
      '/api/knuspr/cart/preview-list/$id';
  static String knusprApplySelections(int id) =>
      '/api/knuspr/cart/apply-selections/$id';
  static const knusprPriceCheck = '/api/knuspr/price-check';
  static const knusprDeliverySlots = '/api/knuspr/delivery-slots';
  static const knusprBookSlot = '/api/knuspr/delivery-slots/book';
  static const knusprCart = '/api/knuspr/cart';
  static const knusprCartGet = '/api/knuspr/cart';
  static String knusprCartItem(String orderFieldId) =>
      '/api/knuspr/cart/items/$orderFieldId';
  static const knusprMappings = '/api/knuspr/mappings';
  static String knusprMapping(int id) => '/api/knuspr/mappings/$id';

  // AI
  static const aiAvailableRecipes = '/api/ai/available-recipes';
  static const aiGenerateMealPlan = '/api/ai/generate-meal-plan';
  static const aiConfirmMealPlan = '/api/ai/confirm-meal-plan';
  static const aiUndoMealPlan = '/api/ai/undo-meal-plan';
  static const aiVoiceCommand = '/api/ai/voice-command';
  static const aiPrioritizeTodos = '/api/ai/prioritize-todos';
  static const aiApplyTodoPriorities = '/api/ai/apply-todo-priorities';
  static const aiCategorizeRecipes = '/api/ai/categorize-recipes';
  static const aiApplyRecipeCategorization =
      '/api/ai/apply-recipe-categorization';

  // Categories
  static const categories = '/api/categories/';
  static String category(int id) => '/api/categories/$id';
  static const categoriesReorder = '/api/categories/reorder';

  // Family Members
  static const familyMembers = '/api/family-members/';
  static String familyMember(int id) => '/api/family-members/$id';

  // Notes
  static const notes = '/api/notes/';
  static String note(int id) => '/api/notes/$id';
  static String notePin(int id) => '/api/notes/$id/pin';
  static String noteArchive(int id) => '/api/notes/$id/archive';
  static String noteColor(int id) => '/api/notes/$id/color';
  static const notesReorder = '/api/notes/reorder';
  static const notesPreviewLink = '/api/notes/preview-link';
  static const notesCheckDuplicate = '/api/notes/check-duplicate-link';
  static String noteConvertToTodo(int id) => '/api/notes/$id/convert-to-todo';
  static String noteComments(int id) => '/api/notes/$id/comments';
  static String noteComment(int noteId, int commentId) =>
      '/api/notes/$noteId/comments/$commentId';
  static String noteAttachments(int id) => '/api/notes/$id/attachments';
  static String noteAttachment(int noteId, int attId) =>
      '/api/notes/$noteId/attachments/$attId';
  static String noteAttachmentDownload(int noteId, int attId) =>
      '/api/notes/$noteId/attachments/$attId/download';

  // Note categories (separate from todo categories)
  static const noteCategories = '/api/note-categories/';
  static String noteCategory(int id) => '/api/note-categories/$id';
  static const noteCategoriesReorder = '/api/note-categories/reorder';

  // Note tags
  static const noteTags = '/api/note-tags/';
  static String noteTag(int id) => '/api/note-tags/$id';
}
