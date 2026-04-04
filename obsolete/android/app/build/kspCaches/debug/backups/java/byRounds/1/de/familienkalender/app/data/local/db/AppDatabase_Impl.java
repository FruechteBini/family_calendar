package de.familienkalender.app.data.local.db;

import androidx.annotation.NonNull;
import androidx.room.DatabaseConfiguration;
import androidx.room.InvalidationTracker;
import androidx.room.RoomDatabase;
import androidx.room.RoomOpenHelper;
import androidx.room.migration.AutoMigrationSpec;
import androidx.room.migration.Migration;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.sqlite.db.SupportSQLiteDatabase;
import androidx.sqlite.db.SupportSQLiteOpenHelper;
import de.familienkalender.app.data.local.db.dao.CategoryDao;
import de.familienkalender.app.data.local.db.dao.CategoryDao_Impl;
import de.familienkalender.app.data.local.db.dao.EventDao;
import de.familienkalender.app.data.local.db.dao.EventDao_Impl;
import de.familienkalender.app.data.local.db.dao.FamilyMemberDao;
import de.familienkalender.app.data.local.db.dao.FamilyMemberDao_Impl;
import de.familienkalender.app.data.local.db.dao.MealPlanDao;
import de.familienkalender.app.data.local.db.dao.MealPlanDao_Impl;
import de.familienkalender.app.data.local.db.dao.PantryDao;
import de.familienkalender.app.data.local.db.dao.PantryDao_Impl;
import de.familienkalender.app.data.local.db.dao.PendingChangeDao;
import de.familienkalender.app.data.local.db.dao.PendingChangeDao_Impl;
import de.familienkalender.app.data.local.db.dao.RecipeDao;
import de.familienkalender.app.data.local.db.dao.RecipeDao_Impl;
import de.familienkalender.app.data.local.db.dao.ShoppingDao;
import de.familienkalender.app.data.local.db.dao.ShoppingDao_Impl;
import de.familienkalender.app.data.local.db.dao.TodoDao;
import de.familienkalender.app.data.local.db.dao.TodoDao_Impl;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class AppDatabase_Impl extends AppDatabase {
  private volatile FamilyMemberDao _familyMemberDao;

  private volatile CategoryDao _categoryDao;

  private volatile EventDao _eventDao;

  private volatile TodoDao _todoDao;

  private volatile RecipeDao _recipeDao;

  private volatile MealPlanDao _mealPlanDao;

  private volatile ShoppingDao _shoppingDao;

  private volatile PantryDao _pantryDao;

  private volatile PendingChangeDao _pendingChangeDao;

  @Override
  @NonNull
  protected SupportSQLiteOpenHelper createOpenHelper(@NonNull final DatabaseConfiguration config) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(config, new RoomOpenHelper.Delegate(2) {
      @Override
      public void createAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `family_members` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `color` TEXT NOT NULL, `avatarEmoji` TEXT NOT NULL, `createdAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `categories` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `color` TEXT NOT NULL, `icon` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `events` (`id` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `start` TEXT NOT NULL, `end` TEXT NOT NULL, `allDay` INTEGER NOT NULL, `categoryId` INTEGER, `categoryName` TEXT, `categoryColor` TEXT, `categoryIcon` TEXT, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `event_members` (`eventId` INTEGER NOT NULL, `memberId` INTEGER NOT NULL, PRIMARY KEY(`eventId`, `memberId`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `todos` (`id` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `priority` TEXT NOT NULL, `dueDate` TEXT, `completed` INTEGER NOT NULL, `completedAt` TEXT, `categoryId` INTEGER, `categoryName` TEXT, `categoryColor` TEXT, `categoryIcon` TEXT, `eventId` INTEGER, `parentId` INTEGER, `requiresMultiple` INTEGER NOT NULL, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `todo_members` (`todoId` INTEGER NOT NULL, `memberId` INTEGER NOT NULL, PRIMARY KEY(`todoId`, `memberId`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `subtodos` (`id` INTEGER NOT NULL, `parentId` INTEGER NOT NULL, `title` TEXT NOT NULL, `completed` INTEGER NOT NULL, `completedAt` TEXT, `createdAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `recipes` (`id` INTEGER NOT NULL, `title` TEXT NOT NULL, `source` TEXT NOT NULL, `cookidooId` TEXT, `servings` INTEGER NOT NULL, `prepTimeActiveMinutes` INTEGER, `prepTimePassiveMinutes` INTEGER, `difficulty` TEXT NOT NULL, `lastCookedAt` TEXT, `cookCount` INTEGER NOT NULL, `notes` TEXT, `imageUrl` TEXT, `aiAccessible` INTEGER NOT NULL, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `ingredients` (`id` INTEGER NOT NULL, `recipeId` INTEGER NOT NULL, `name` TEXT NOT NULL, `amount` REAL, `unit` TEXT, `category` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `meal_plan` (`id` INTEGER NOT NULL, `planDate` TEXT NOT NULL, `slot` TEXT NOT NULL, `recipeId` INTEGER NOT NULL, `servingsPlanned` INTEGER NOT NULL, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `cooking_history` (`id` INTEGER NOT NULL, `recipeId` INTEGER NOT NULL, `cookedAt` TEXT NOT NULL, `servingsCooked` INTEGER NOT NULL, `rating` INTEGER, `notes` TEXT, `createdAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `shopping_lists` (`id` INTEGER NOT NULL, `weekStartDate` TEXT NOT NULL, `status` TEXT NOT NULL, `sortedByStore` TEXT, `createdAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `shopping_items` (`id` INTEGER NOT NULL, `shoppingListId` INTEGER NOT NULL, `name` TEXT NOT NULL, `amount` TEXT, `unit` TEXT, `category` TEXT NOT NULL, `checked` INTEGER NOT NULL, `source` TEXT NOT NULL, `recipeId` INTEGER, `aiAccessible` INTEGER NOT NULL, `sortOrder` INTEGER, `storeSection` TEXT, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `pantry_items` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, `amount` REAL, `unit` TEXT, `category` TEXT NOT NULL, `expiryDate` TEXT, `minStock` REAL, `isLowStock` INTEGER NOT NULL, `isExpiringSoon` INTEGER NOT NULL, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE TABLE IF NOT EXISTS `pending_changes` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `entityType` TEXT NOT NULL, `entityId` INTEGER, `action` TEXT NOT NULL, `endpoint` TEXT NOT NULL, `payload` TEXT, `createdAt` INTEGER NOT NULL)");
        db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '6d94bbb2876fc119cd79b71a53ad3d0e')");
      }

      @Override
      public void dropAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("DROP TABLE IF EXISTS `family_members`");
        db.execSQL("DROP TABLE IF EXISTS `categories`");
        db.execSQL("DROP TABLE IF EXISTS `events`");
        db.execSQL("DROP TABLE IF EXISTS `event_members`");
        db.execSQL("DROP TABLE IF EXISTS `todos`");
        db.execSQL("DROP TABLE IF EXISTS `todo_members`");
        db.execSQL("DROP TABLE IF EXISTS `subtodos`");
        db.execSQL("DROP TABLE IF EXISTS `recipes`");
        db.execSQL("DROP TABLE IF EXISTS `ingredients`");
        db.execSQL("DROP TABLE IF EXISTS `meal_plan`");
        db.execSQL("DROP TABLE IF EXISTS `cooking_history`");
        db.execSQL("DROP TABLE IF EXISTS `shopping_lists`");
        db.execSQL("DROP TABLE IF EXISTS `shopping_items`");
        db.execSQL("DROP TABLE IF EXISTS `pantry_items`");
        db.execSQL("DROP TABLE IF EXISTS `pending_changes`");
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onDestructiveMigration(db);
          }
        }
      }

      @Override
      public void onCreate(@NonNull final SupportSQLiteDatabase db) {
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onCreate(db);
          }
        }
      }

      @Override
      public void onOpen(@NonNull final SupportSQLiteDatabase db) {
        mDatabase = db;
        internalInitInvalidationTracker(db);
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onOpen(db);
          }
        }
      }

      @Override
      public void onPreMigrate(@NonNull final SupportSQLiteDatabase db) {
        DBUtil.dropFtsSyncTriggers(db);
      }

      @Override
      public void onPostMigrate(@NonNull final SupportSQLiteDatabase db) {
      }

      @Override
      @NonNull
      public RoomOpenHelper.ValidationResult onValidateSchema(
          @NonNull final SupportSQLiteDatabase db) {
        final HashMap<String, TableInfo.Column> _columnsFamilyMembers = new HashMap<String, TableInfo.Column>(5);
        _columnsFamilyMembers.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsFamilyMembers.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsFamilyMembers.put("color", new TableInfo.Column("color", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsFamilyMembers.put("avatarEmoji", new TableInfo.Column("avatarEmoji", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsFamilyMembers.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysFamilyMembers = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesFamilyMembers = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoFamilyMembers = new TableInfo("family_members", _columnsFamilyMembers, _foreignKeysFamilyMembers, _indicesFamilyMembers);
        final TableInfo _existingFamilyMembers = TableInfo.read(db, "family_members");
        if (!_infoFamilyMembers.equals(_existingFamilyMembers)) {
          return new RoomOpenHelper.ValidationResult(false, "family_members(de.familienkalender.app.data.local.db.entity.FamilyMemberEntity).\n"
                  + " Expected:\n" + _infoFamilyMembers + "\n"
                  + " Found:\n" + _existingFamilyMembers);
        }
        final HashMap<String, TableInfo.Column> _columnsCategories = new HashMap<String, TableInfo.Column>(4);
        _columnsCategories.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCategories.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCategories.put("color", new TableInfo.Column("color", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCategories.put("icon", new TableInfo.Column("icon", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysCategories = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesCategories = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoCategories = new TableInfo("categories", _columnsCategories, _foreignKeysCategories, _indicesCategories);
        final TableInfo _existingCategories = TableInfo.read(db, "categories");
        if (!_infoCategories.equals(_existingCategories)) {
          return new RoomOpenHelper.ValidationResult(false, "categories(de.familienkalender.app.data.local.db.entity.CategoryEntity).\n"
                  + " Expected:\n" + _infoCategories + "\n"
                  + " Found:\n" + _existingCategories);
        }
        final HashMap<String, TableInfo.Column> _columnsEvents = new HashMap<String, TableInfo.Column>(12);
        _columnsEvents.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("description", new TableInfo.Column("description", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("start", new TableInfo.Column("start", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("end", new TableInfo.Column("end", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("allDay", new TableInfo.Column("allDay", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("categoryId", new TableInfo.Column("categoryId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("categoryName", new TableInfo.Column("categoryName", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("categoryColor", new TableInfo.Column("categoryColor", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("categoryIcon", new TableInfo.Column("categoryIcon", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEvents.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysEvents = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesEvents = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoEvents = new TableInfo("events", _columnsEvents, _foreignKeysEvents, _indicesEvents);
        final TableInfo _existingEvents = TableInfo.read(db, "events");
        if (!_infoEvents.equals(_existingEvents)) {
          return new RoomOpenHelper.ValidationResult(false, "events(de.familienkalender.app.data.local.db.entity.EventEntity).\n"
                  + " Expected:\n" + _infoEvents + "\n"
                  + " Found:\n" + _existingEvents);
        }
        final HashMap<String, TableInfo.Column> _columnsEventMembers = new HashMap<String, TableInfo.Column>(2);
        _columnsEventMembers.put("eventId", new TableInfo.Column("eventId", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsEventMembers.put("memberId", new TableInfo.Column("memberId", "INTEGER", true, 2, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysEventMembers = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesEventMembers = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoEventMembers = new TableInfo("event_members", _columnsEventMembers, _foreignKeysEventMembers, _indicesEventMembers);
        final TableInfo _existingEventMembers = TableInfo.read(db, "event_members");
        if (!_infoEventMembers.equals(_existingEventMembers)) {
          return new RoomOpenHelper.ValidationResult(false, "event_members(de.familienkalender.app.data.local.db.entity.EventMemberCrossRef).\n"
                  + " Expected:\n" + _infoEventMembers + "\n"
                  + " Found:\n" + _existingEventMembers);
        }
        final HashMap<String, TableInfo.Column> _columnsTodos = new HashMap<String, TableInfo.Column>(16);
        _columnsTodos.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("description", new TableInfo.Column("description", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("priority", new TableInfo.Column("priority", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("dueDate", new TableInfo.Column("dueDate", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("completed", new TableInfo.Column("completed", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("completedAt", new TableInfo.Column("completedAt", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("categoryId", new TableInfo.Column("categoryId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("categoryName", new TableInfo.Column("categoryName", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("categoryColor", new TableInfo.Column("categoryColor", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("categoryIcon", new TableInfo.Column("categoryIcon", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("eventId", new TableInfo.Column("eventId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("parentId", new TableInfo.Column("parentId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("requiresMultiple", new TableInfo.Column("requiresMultiple", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodos.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysTodos = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesTodos = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoTodos = new TableInfo("todos", _columnsTodos, _foreignKeysTodos, _indicesTodos);
        final TableInfo _existingTodos = TableInfo.read(db, "todos");
        if (!_infoTodos.equals(_existingTodos)) {
          return new RoomOpenHelper.ValidationResult(false, "todos(de.familienkalender.app.data.local.db.entity.TodoEntity).\n"
                  + " Expected:\n" + _infoTodos + "\n"
                  + " Found:\n" + _existingTodos);
        }
        final HashMap<String, TableInfo.Column> _columnsTodoMembers = new HashMap<String, TableInfo.Column>(2);
        _columnsTodoMembers.put("todoId", new TableInfo.Column("todoId", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTodoMembers.put("memberId", new TableInfo.Column("memberId", "INTEGER", true, 2, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysTodoMembers = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesTodoMembers = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoTodoMembers = new TableInfo("todo_members", _columnsTodoMembers, _foreignKeysTodoMembers, _indicesTodoMembers);
        final TableInfo _existingTodoMembers = TableInfo.read(db, "todo_members");
        if (!_infoTodoMembers.equals(_existingTodoMembers)) {
          return new RoomOpenHelper.ValidationResult(false, "todo_members(de.familienkalender.app.data.local.db.entity.TodoMemberCrossRef).\n"
                  + " Expected:\n" + _infoTodoMembers + "\n"
                  + " Found:\n" + _existingTodoMembers);
        }
        final HashMap<String, TableInfo.Column> _columnsSubtodos = new HashMap<String, TableInfo.Column>(6);
        _columnsSubtodos.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSubtodos.put("parentId", new TableInfo.Column("parentId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSubtodos.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSubtodos.put("completed", new TableInfo.Column("completed", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSubtodos.put("completedAt", new TableInfo.Column("completedAt", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSubtodos.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysSubtodos = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesSubtodos = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoSubtodos = new TableInfo("subtodos", _columnsSubtodos, _foreignKeysSubtodos, _indicesSubtodos);
        final TableInfo _existingSubtodos = TableInfo.read(db, "subtodos");
        if (!_infoSubtodos.equals(_existingSubtodos)) {
          return new RoomOpenHelper.ValidationResult(false, "subtodos(de.familienkalender.app.data.local.db.entity.SubtodoEntity).\n"
                  + " Expected:\n" + _infoSubtodos + "\n"
                  + " Found:\n" + _existingSubtodos);
        }
        final HashMap<String, TableInfo.Column> _columnsRecipes = new HashMap<String, TableInfo.Column>(15);
        _columnsRecipes.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("source", new TableInfo.Column("source", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("cookidooId", new TableInfo.Column("cookidooId", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("servings", new TableInfo.Column("servings", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("prepTimeActiveMinutes", new TableInfo.Column("prepTimeActiveMinutes", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("prepTimePassiveMinutes", new TableInfo.Column("prepTimePassiveMinutes", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("difficulty", new TableInfo.Column("difficulty", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("lastCookedAt", new TableInfo.Column("lastCookedAt", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("cookCount", new TableInfo.Column("cookCount", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("notes", new TableInfo.Column("notes", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("imageUrl", new TableInfo.Column("imageUrl", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("aiAccessible", new TableInfo.Column("aiAccessible", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsRecipes.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysRecipes = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesRecipes = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoRecipes = new TableInfo("recipes", _columnsRecipes, _foreignKeysRecipes, _indicesRecipes);
        final TableInfo _existingRecipes = TableInfo.read(db, "recipes");
        if (!_infoRecipes.equals(_existingRecipes)) {
          return new RoomOpenHelper.ValidationResult(false, "recipes(de.familienkalender.app.data.local.db.entity.RecipeEntity).\n"
                  + " Expected:\n" + _infoRecipes + "\n"
                  + " Found:\n" + _existingRecipes);
        }
        final HashMap<String, TableInfo.Column> _columnsIngredients = new HashMap<String, TableInfo.Column>(6);
        _columnsIngredients.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsIngredients.put("recipeId", new TableInfo.Column("recipeId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsIngredients.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsIngredients.put("amount", new TableInfo.Column("amount", "REAL", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsIngredients.put("unit", new TableInfo.Column("unit", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsIngredients.put("category", new TableInfo.Column("category", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysIngredients = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesIngredients = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoIngredients = new TableInfo("ingredients", _columnsIngredients, _foreignKeysIngredients, _indicesIngredients);
        final TableInfo _existingIngredients = TableInfo.read(db, "ingredients");
        if (!_infoIngredients.equals(_existingIngredients)) {
          return new RoomOpenHelper.ValidationResult(false, "ingredients(de.familienkalender.app.data.local.db.entity.IngredientEntity).\n"
                  + " Expected:\n" + _infoIngredients + "\n"
                  + " Found:\n" + _existingIngredients);
        }
        final HashMap<String, TableInfo.Column> _columnsMealPlan = new HashMap<String, TableInfo.Column>(7);
        _columnsMealPlan.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("planDate", new TableInfo.Column("planDate", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("slot", new TableInfo.Column("slot", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("recipeId", new TableInfo.Column("recipeId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("servingsPlanned", new TableInfo.Column("servingsPlanned", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsMealPlan.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysMealPlan = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesMealPlan = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoMealPlan = new TableInfo("meal_plan", _columnsMealPlan, _foreignKeysMealPlan, _indicesMealPlan);
        final TableInfo _existingMealPlan = TableInfo.read(db, "meal_plan");
        if (!_infoMealPlan.equals(_existingMealPlan)) {
          return new RoomOpenHelper.ValidationResult(false, "meal_plan(de.familienkalender.app.data.local.db.entity.MealPlanEntity).\n"
                  + " Expected:\n" + _infoMealPlan + "\n"
                  + " Found:\n" + _existingMealPlan);
        }
        final HashMap<String, TableInfo.Column> _columnsCookingHistory = new HashMap<String, TableInfo.Column>(7);
        _columnsCookingHistory.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("recipeId", new TableInfo.Column("recipeId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("cookedAt", new TableInfo.Column("cookedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("servingsCooked", new TableInfo.Column("servingsCooked", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("rating", new TableInfo.Column("rating", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("notes", new TableInfo.Column("notes", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCookingHistory.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysCookingHistory = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesCookingHistory = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoCookingHistory = new TableInfo("cooking_history", _columnsCookingHistory, _foreignKeysCookingHistory, _indicesCookingHistory);
        final TableInfo _existingCookingHistory = TableInfo.read(db, "cooking_history");
        if (!_infoCookingHistory.equals(_existingCookingHistory)) {
          return new RoomOpenHelper.ValidationResult(false, "cooking_history(de.familienkalender.app.data.local.db.entity.CookingHistoryEntity).\n"
                  + " Expected:\n" + _infoCookingHistory + "\n"
                  + " Found:\n" + _existingCookingHistory);
        }
        final HashMap<String, TableInfo.Column> _columnsShoppingLists = new HashMap<String, TableInfo.Column>(5);
        _columnsShoppingLists.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingLists.put("weekStartDate", new TableInfo.Column("weekStartDate", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingLists.put("status", new TableInfo.Column("status", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingLists.put("sortedByStore", new TableInfo.Column("sortedByStore", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingLists.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysShoppingLists = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesShoppingLists = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoShoppingLists = new TableInfo("shopping_lists", _columnsShoppingLists, _foreignKeysShoppingLists, _indicesShoppingLists);
        final TableInfo _existingShoppingLists = TableInfo.read(db, "shopping_lists");
        if (!_infoShoppingLists.equals(_existingShoppingLists)) {
          return new RoomOpenHelper.ValidationResult(false, "shopping_lists(de.familienkalender.app.data.local.db.entity.ShoppingListEntity).\n"
                  + " Expected:\n" + _infoShoppingLists + "\n"
                  + " Found:\n" + _existingShoppingLists);
        }
        final HashMap<String, TableInfo.Column> _columnsShoppingItems = new HashMap<String, TableInfo.Column>(14);
        _columnsShoppingItems.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("shoppingListId", new TableInfo.Column("shoppingListId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("amount", new TableInfo.Column("amount", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("unit", new TableInfo.Column("unit", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("category", new TableInfo.Column("category", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("checked", new TableInfo.Column("checked", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("source", new TableInfo.Column("source", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("recipeId", new TableInfo.Column("recipeId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("aiAccessible", new TableInfo.Column("aiAccessible", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("sortOrder", new TableInfo.Column("sortOrder", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("storeSection", new TableInfo.Column("storeSection", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsShoppingItems.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysShoppingItems = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesShoppingItems = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoShoppingItems = new TableInfo("shopping_items", _columnsShoppingItems, _foreignKeysShoppingItems, _indicesShoppingItems);
        final TableInfo _existingShoppingItems = TableInfo.read(db, "shopping_items");
        if (!_infoShoppingItems.equals(_existingShoppingItems)) {
          return new RoomOpenHelper.ValidationResult(false, "shopping_items(de.familienkalender.app.data.local.db.entity.ShoppingItemEntity).\n"
                  + " Expected:\n" + _infoShoppingItems + "\n"
                  + " Found:\n" + _existingShoppingItems);
        }
        final HashMap<String, TableInfo.Column> _columnsPantryItems = new HashMap<String, TableInfo.Column>(11);
        _columnsPantryItems.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("name", new TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("amount", new TableInfo.Column("amount", "REAL", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("unit", new TableInfo.Column("unit", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("category", new TableInfo.Column("category", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("expiryDate", new TableInfo.Column("expiryDate", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("minStock", new TableInfo.Column("minStock", "REAL", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("isLowStock", new TableInfo.Column("isLowStock", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("isExpiringSoon", new TableInfo.Column("isExpiringSoon", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("createdAt", new TableInfo.Column("createdAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPantryItems.put("updatedAt", new TableInfo.Column("updatedAt", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysPantryItems = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesPantryItems = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoPantryItems = new TableInfo("pantry_items", _columnsPantryItems, _foreignKeysPantryItems, _indicesPantryItems);
        final TableInfo _existingPantryItems = TableInfo.read(db, "pantry_items");
        if (!_infoPantryItems.equals(_existingPantryItems)) {
          return new RoomOpenHelper.ValidationResult(false, "pantry_items(de.familienkalender.app.data.local.db.entity.PantryItemEntity).\n"
                  + " Expected:\n" + _infoPantryItems + "\n"
                  + " Found:\n" + _existingPantryItems);
        }
        final HashMap<String, TableInfo.Column> _columnsPendingChanges = new HashMap<String, TableInfo.Column>(7);
        _columnsPendingChanges.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("entityType", new TableInfo.Column("entityType", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("entityId", new TableInfo.Column("entityId", "INTEGER", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("action", new TableInfo.Column("action", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("endpoint", new TableInfo.Column("endpoint", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("payload", new TableInfo.Column("payload", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsPendingChanges.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysPendingChanges = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesPendingChanges = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoPendingChanges = new TableInfo("pending_changes", _columnsPendingChanges, _foreignKeysPendingChanges, _indicesPendingChanges);
        final TableInfo _existingPendingChanges = TableInfo.read(db, "pending_changes");
        if (!_infoPendingChanges.equals(_existingPendingChanges)) {
          return new RoomOpenHelper.ValidationResult(false, "pending_changes(de.familienkalender.app.data.local.db.entity.PendingChangeEntity).\n"
                  + " Expected:\n" + _infoPendingChanges + "\n"
                  + " Found:\n" + _existingPendingChanges);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "6d94bbb2876fc119cd79b71a53ad3d0e", "81c7d3368d09d120dacccbd8b5e2532f");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(config.context).name(config.name).callback(_openCallback).build();
    final SupportSQLiteOpenHelper _helper = config.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "family_members","categories","events","event_members","todos","todo_members","subtodos","recipes","ingredients","meal_plan","cooking_history","shopping_lists","shopping_items","pantry_items","pending_changes");
  }

  @Override
  public void clearAllTables() {
    super.assertNotMainThread();
    final SupportSQLiteDatabase _db = super.getOpenHelper().getWritableDatabase();
    try {
      super.beginTransaction();
      _db.execSQL("DELETE FROM `family_members`");
      _db.execSQL("DELETE FROM `categories`");
      _db.execSQL("DELETE FROM `events`");
      _db.execSQL("DELETE FROM `event_members`");
      _db.execSQL("DELETE FROM `todos`");
      _db.execSQL("DELETE FROM `todo_members`");
      _db.execSQL("DELETE FROM `subtodos`");
      _db.execSQL("DELETE FROM `recipes`");
      _db.execSQL("DELETE FROM `ingredients`");
      _db.execSQL("DELETE FROM `meal_plan`");
      _db.execSQL("DELETE FROM `cooking_history`");
      _db.execSQL("DELETE FROM `shopping_lists`");
      _db.execSQL("DELETE FROM `shopping_items`");
      _db.execSQL("DELETE FROM `pantry_items`");
      _db.execSQL("DELETE FROM `pending_changes`");
      super.setTransactionSuccessful();
    } finally {
      super.endTransaction();
      _db.query("PRAGMA wal_checkpoint(FULL)").close();
      if (!_db.inTransaction()) {
        _db.execSQL("VACUUM");
      }
    }
  }

  @Override
  @NonNull
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final HashMap<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(FamilyMemberDao.class, FamilyMemberDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(CategoryDao.class, CategoryDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(EventDao.class, EventDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(TodoDao.class, TodoDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(RecipeDao.class, RecipeDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(MealPlanDao.class, MealPlanDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(ShoppingDao.class, ShoppingDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(PantryDao.class, PantryDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(PendingChangeDao.class, PendingChangeDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  @NonNull
  public Set<Class<? extends AutoMigrationSpec>> getRequiredAutoMigrationSpecs() {
    final HashSet<Class<? extends AutoMigrationSpec>> _autoMigrationSpecsSet = new HashSet<Class<? extends AutoMigrationSpec>>();
    return _autoMigrationSpecsSet;
  }

  @Override
  @NonNull
  public List<Migration> getAutoMigrations(
      @NonNull final Map<Class<? extends AutoMigrationSpec>, AutoMigrationSpec> autoMigrationSpecs) {
    final List<Migration> _autoMigrations = new ArrayList<Migration>();
    return _autoMigrations;
  }

  @Override
  public FamilyMemberDao familyMemberDao() {
    if (_familyMemberDao != null) {
      return _familyMemberDao;
    } else {
      synchronized(this) {
        if(_familyMemberDao == null) {
          _familyMemberDao = new FamilyMemberDao_Impl(this);
        }
        return _familyMemberDao;
      }
    }
  }

  @Override
  public CategoryDao categoryDao() {
    if (_categoryDao != null) {
      return _categoryDao;
    } else {
      synchronized(this) {
        if(_categoryDao == null) {
          _categoryDao = new CategoryDao_Impl(this);
        }
        return _categoryDao;
      }
    }
  }

  @Override
  public EventDao eventDao() {
    if (_eventDao != null) {
      return _eventDao;
    } else {
      synchronized(this) {
        if(_eventDao == null) {
          _eventDao = new EventDao_Impl(this);
        }
        return _eventDao;
      }
    }
  }

  @Override
  public TodoDao todoDao() {
    if (_todoDao != null) {
      return _todoDao;
    } else {
      synchronized(this) {
        if(_todoDao == null) {
          _todoDao = new TodoDao_Impl(this);
        }
        return _todoDao;
      }
    }
  }

  @Override
  public RecipeDao recipeDao() {
    if (_recipeDao != null) {
      return _recipeDao;
    } else {
      synchronized(this) {
        if(_recipeDao == null) {
          _recipeDao = new RecipeDao_Impl(this);
        }
        return _recipeDao;
      }
    }
  }

  @Override
  public MealPlanDao mealPlanDao() {
    if (_mealPlanDao != null) {
      return _mealPlanDao;
    } else {
      synchronized(this) {
        if(_mealPlanDao == null) {
          _mealPlanDao = new MealPlanDao_Impl(this);
        }
        return _mealPlanDao;
      }
    }
  }

  @Override
  public ShoppingDao shoppingDao() {
    if (_shoppingDao != null) {
      return _shoppingDao;
    } else {
      synchronized(this) {
        if(_shoppingDao == null) {
          _shoppingDao = new ShoppingDao_Impl(this);
        }
        return _shoppingDao;
      }
    }
  }

  @Override
  public PantryDao pantryDao() {
    if (_pantryDao != null) {
      return _pantryDao;
    } else {
      synchronized(this) {
        if(_pantryDao == null) {
          _pantryDao = new PantryDao_Impl(this);
        }
        return _pantryDao;
      }
    }
  }

  @Override
  public PendingChangeDao pendingChangeDao() {
    if (_pendingChangeDao != null) {
      return _pendingChangeDao;
    } else {
      synchronized(this) {
        if(_pendingChangeDao == null) {
          _pendingChangeDao = new PendingChangeDao_Impl(this);
        }
        return _pendingChangeDao;
      }
    }
  }
}
