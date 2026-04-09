import 'package:drift/drift.dart';

class CachedEvents extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get categoryColor => text().nullable()();
  TextColumn get memberIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get membersJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedTodos extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('none'))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get eventId => integer().nullable()();
  IntColumn get parentId => integer().nullable()();
  BoolColumn get requiresMultiple => boolean().withDefault(const Constant(false))();
  TextColumn get memberIdsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedRecipes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant('mittel'))();
  IntColumn get prepTime => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isCookidoo => boolean().withDefault(const Constant(false))();
  TextColumn get ingredientsJson => text().withDefault(const Constant('[]'))();
  IntColumn get recipeCategoryId => integer().nullable()();
  TextColumn get recipeCategoryName => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedRecipeCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedFamilyMembers extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedShoppingItems extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  RealColumn get amount => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  IntColumn get sortOrder => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedNotes extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get content => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get linkTitle => text().nullable()();
  TextColumn get linkThumbnailUrl => text().nullable()();
  TextColumn get linkDomain => text().nullable()();
  TextColumn get checklistJson => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  BoolColumn get isPersonal => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedNoteCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedPantryItems extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  IntColumn get lowStockThreshold => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingChanges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // CREATE, UPDATE, PATCH, DELETE
  TextColumn get endpoint => text()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
