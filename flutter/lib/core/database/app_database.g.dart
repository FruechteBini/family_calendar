// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEventsTable extends CachedEvents
    with TableInfo<$CachedEventsTable, CachedEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryColorMeta =
      const VerificationMeta('categoryColor');
  @override
  late final GeneratedColumn<String> categoryColor = GeneratedColumn<String>(
      'category_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memberIdsJsonMeta =
      const VerificationMeta('memberIdsJson');
  @override
  late final GeneratedColumn<String> memberIdsJson = GeneratedColumn<String>(
      'member_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _membersJsonMeta =
      const VerificationMeta('membersJson');
  @override
  late final GeneratedColumn<String> membersJson = GeneratedColumn<String>(
      'members_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startTime,
        endTime,
        allDay,
        categoryId,
        categoryName,
        categoryColor,
        memberIdsJson,
        membersJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_events';
  @override
  VerificationContext validateIntegrity(Insertable<CachedEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('category_color')) {
      context.handle(
          _categoryColorMeta,
          categoryColor.isAcceptableOrUnknown(
              data['category_color']!, _categoryColorMeta));
    }
    if (data.containsKey('member_ids_json')) {
      context.handle(
          _memberIdsJsonMeta,
          memberIdsJson.isAcceptableOrUnknown(
              data['member_ids_json']!, _memberIdsJsonMeta));
    }
    if (data.containsKey('members_json')) {
      context.handle(
          _membersJsonMeta,
          membersJson.isAcceptableOrUnknown(
              data['members_json']!, _membersJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      categoryColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_color']),
      memberIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}member_ids_json'])!,
      membersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}members_json'])!,
    );
  }

  @override
  $CachedEventsTable createAlias(String alias) {
    return $CachedEventsTable(attachedDatabase, alias);
  }
}

class CachedEvent extends DataClass implements Insertable<CachedEvent> {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String memberIdsJson;
  final String membersJson;
  const CachedEvent(
      {required this.id,
      required this.title,
      this.description,
      required this.startTime,
      required this.endTime,
      required this.allDay,
      this.categoryId,
      this.categoryName,
      this.categoryColor,
      required this.memberIdsJson,
      required this.membersJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || categoryColor != null) {
      map['category_color'] = Variable<String>(categoryColor);
    }
    map['member_ids_json'] = Variable<String>(memberIdsJson);
    map['members_json'] = Variable<String>(membersJson);
    return map;
  }

  CachedEventsCompanion toCompanion(bool nullToAbsent) {
    return CachedEventsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      allDay: Value(allDay),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryColor: categoryColor == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryColor),
      memberIdsJson: Value(memberIdsJson),
      membersJson: Value(membersJson),
    );
  }

  factory CachedEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEvent(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryColor: serializer.fromJson<String?>(json['categoryColor']),
      memberIdsJson: serializer.fromJson<String>(json['memberIdsJson']),
      membersJson: serializer.fromJson<String>(json['membersJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'allDay': serializer.toJson<bool>(allDay),
      'categoryId': serializer.toJson<int?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryColor': serializer.toJson<String?>(categoryColor),
      'memberIdsJson': serializer.toJson<String>(memberIdsJson),
      'membersJson': serializer.toJson<String>(membersJson),
    };
  }

  CachedEvent copyWith(
          {int? id,
          String? title,
          Value<String?> description = const Value.absent(),
          DateTime? startTime,
          DateTime? endTime,
          bool? allDay,
          Value<int?> categoryId = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<String?> categoryColor = const Value.absent(),
          String? memberIdsJson,
          String? membersJson}) =>
      CachedEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        allDay: allDay ?? this.allDay,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        categoryColor:
            categoryColor.present ? categoryColor.value : this.categoryColor,
        memberIdsJson: memberIdsJson ?? this.memberIdsJson,
        membersJson: membersJson ?? this.membersJson,
      );
  CachedEvent copyWithCompanion(CachedEventsCompanion data) {
    return CachedEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryColor: data.categoryColor.present
          ? data.categoryColor.value
          : this.categoryColor,
      memberIdsJson: data.memberIdsJson.present
          ? data.memberIdsJson.value
          : this.memberIdsJson,
      membersJson:
          data.membersJson.present ? data.membersJson.value : this.membersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('memberIdsJson: $memberIdsJson, ')
          ..write('membersJson: $membersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      allDay,
      categoryId,
      categoryName,
      categoryColor,
      memberIdsJson,
      membersJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.allDay == this.allDay &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.categoryColor == this.categoryColor &&
          other.memberIdsJson == this.memberIdsJson &&
          other.membersJson == this.membersJson);
}

class CachedEventsCompanion extends UpdateCompanion<CachedEvent> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<bool> allDay;
  final Value<int?> categoryId;
  final Value<String?> categoryName;
  final Value<String?> categoryColor;
  final Value<String> memberIdsJson;
  final Value<String> membersJson;
  const CachedEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryColor = const Value.absent(),
    this.memberIdsJson = const Value.absent(),
    this.membersJson = const Value.absent(),
  });
  CachedEventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.allDay = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryColor = const Value.absent(),
    this.memberIdsJson = const Value.absent(),
    this.membersJson = const Value.absent(),
  })  : title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime);
  static Insertable<CachedEvent> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? allDay,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? categoryColor,
    Expression<String>? memberIdsJson,
    Expression<String>? membersJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (allDay != null) 'all_day': allDay,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryColor != null) 'category_color': categoryColor,
      if (memberIdsJson != null) 'member_ids_json': memberIdsJson,
      if (membersJson != null) 'members_json': membersJson,
    });
  }

  CachedEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<bool>? allDay,
      Value<int?>? categoryId,
      Value<String?>? categoryName,
      Value<String?>? categoryColor,
      Value<String>? memberIdsJson,
      Value<String>? membersJson}) {
    return CachedEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      memberIdsJson: memberIdsJson ?? this.memberIdsJson,
      membersJson: membersJson ?? this.membersJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryColor.present) {
      map['category_color'] = Variable<String>(categoryColor.value);
    }
    if (memberIdsJson.present) {
      map['member_ids_json'] = Variable<String>(memberIdsJson.value);
    }
    if (membersJson.present) {
      map['members_json'] = Variable<String>(membersJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('memberIdsJson: $memberIdsJson, ')
          ..write('membersJson: $membersJson')
          ..write(')'))
        .toString();
  }
}

class $CachedTodosTable extends CachedTodos
    with TableInfo<$CachedTodosTable, CachedTodo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
      'event_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _requiresMultipleMeta =
      const VerificationMeta('requiresMultiple');
  @override
  late final GeneratedColumn<bool> requiresMultiple = GeneratedColumn<bool>(
      'requires_multiple', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_multiple" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _memberIdsJsonMeta =
      const VerificationMeta('memberIdsJson');
  @override
  late final GeneratedColumn<String> memberIdsJson = GeneratedColumn<String>(
      'member_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        priority,
        completed,
        dueDate,
        categoryId,
        categoryName,
        eventId,
        parentId,
        requiresMultiple,
        memberIdsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_todos';
  @override
  VerificationContext validateIntegrity(Insertable<CachedTodo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('requires_multiple')) {
      context.handle(
          _requiresMultipleMeta,
          requiresMultiple.isAcceptableOrUnknown(
              data['requires_multiple']!, _requiresMultipleMeta));
    }
    if (data.containsKey('member_ids_json')) {
      context.handle(
          _memberIdsJsonMeta,
          memberIdsJson.isAcceptableOrUnknown(
              data['member_ids_json']!, _memberIdsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTodo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTodo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_id']),
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      requiresMultiple: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}requires_multiple'])!,
      memberIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}member_ids_json'])!,
    );
  }

  @override
  $CachedTodosTable createAlias(String alias) {
    return $CachedTodosTable(attachedDatabase, alias);
  }
}

class CachedTodo extends DataClass implements Insertable<CachedTodo> {
  final int id;
  final String title;
  final String? description;
  final String priority;
  final bool completed;
  final DateTime? dueDate;
  final int? categoryId;
  final String? categoryName;
  final int? eventId;
  final int? parentId;
  final bool requiresMultiple;
  final String memberIdsJson;
  const CachedTodo(
      {required this.id,
      required this.title,
      this.description,
      required this.priority,
      required this.completed,
      this.dueDate,
      this.categoryId,
      this.categoryName,
      this.eventId,
      this.parentId,
      required this.requiresMultiple,
      required this.memberIdsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<String>(priority);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['requires_multiple'] = Variable<bool>(requiresMultiple);
    map['member_ids_json'] = Variable<String>(memberIdsJson);
    return map;
  }

  CachedTodosCompanion toCompanion(bool nullToAbsent) {
    return CachedTodosCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      completed: Value(completed),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      requiresMultiple: Value(requiresMultiple),
      memberIdsJson: Value(memberIdsJson),
    );
  }

  factory CachedTodo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTodo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<String>(json['priority']),
      completed: serializer.fromJson<bool>(json['completed']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      eventId: serializer.fromJson<int?>(json['eventId']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      requiresMultiple: serializer.fromJson<bool>(json['requiresMultiple']),
      memberIdsJson: serializer.fromJson<String>(json['memberIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<String>(priority),
      'completed': serializer.toJson<bool>(completed),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'categoryId': serializer.toJson<int?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'eventId': serializer.toJson<int?>(eventId),
      'parentId': serializer.toJson<int?>(parentId),
      'requiresMultiple': serializer.toJson<bool>(requiresMultiple),
      'memberIdsJson': serializer.toJson<String>(memberIdsJson),
    };
  }

  CachedTodo copyWith(
          {int? id,
          String? title,
          Value<String?> description = const Value.absent(),
          String? priority,
          bool? completed,
          Value<DateTime?> dueDate = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<int?> eventId = const Value.absent(),
          Value<int?> parentId = const Value.absent(),
          bool? requiresMultiple,
          String? memberIdsJson}) =>
      CachedTodo(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        priority: priority ?? this.priority,
        completed: completed ?? this.completed,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        eventId: eventId.present ? eventId.value : this.eventId,
        parentId: parentId.present ? parentId.value : this.parentId,
        requiresMultiple: requiresMultiple ?? this.requiresMultiple,
        memberIdsJson: memberIdsJson ?? this.memberIdsJson,
      );
  CachedTodo copyWithCompanion(CachedTodosCompanion data) {
    return CachedTodo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      completed: data.completed.present ? data.completed.value : this.completed,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      requiresMultiple: data.requiresMultiple.present
          ? data.requiresMultiple.value
          : this.requiresMultiple,
      memberIdsJson: data.memberIdsJson.present
          ? data.memberIdsJson.value
          : this.memberIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTodo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('completed: $completed, ')
          ..write('dueDate: $dueDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('eventId: $eventId, ')
          ..write('parentId: $parentId, ')
          ..write('requiresMultiple: $requiresMultiple, ')
          ..write('memberIdsJson: $memberIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      priority,
      completed,
      dueDate,
      categoryId,
      categoryName,
      eventId,
      parentId,
      requiresMultiple,
      memberIdsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTodo &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.completed == this.completed &&
          other.dueDate == this.dueDate &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.eventId == this.eventId &&
          other.parentId == this.parentId &&
          other.requiresMultiple == this.requiresMultiple &&
          other.memberIdsJson == this.memberIdsJson);
}

class CachedTodosCompanion extends UpdateCompanion<CachedTodo> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> priority;
  final Value<bool> completed;
  final Value<DateTime?> dueDate;
  final Value<int?> categoryId;
  final Value<String?> categoryName;
  final Value<int?> eventId;
  final Value<int?> parentId;
  final Value<bool> requiresMultiple;
  final Value<String> memberIdsJson;
  const CachedTodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.completed = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.eventId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.requiresMultiple = const Value.absent(),
    this.memberIdsJson = const Value.absent(),
  });
  CachedTodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.completed = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.eventId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.requiresMultiple = const Value.absent(),
    this.memberIdsJson = const Value.absent(),
  }) : title = Value(title);
  static Insertable<CachedTodo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? priority,
    Expression<bool>? completed,
    Expression<DateTime>? dueDate,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? eventId,
    Expression<int>? parentId,
    Expression<bool>? requiresMultiple,
    Expression<String>? memberIdsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (completed != null) 'completed': completed,
      if (dueDate != null) 'due_date': dueDate,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (eventId != null) 'event_id': eventId,
      if (parentId != null) 'parent_id': parentId,
      if (requiresMultiple != null) 'requires_multiple': requiresMultiple,
      if (memberIdsJson != null) 'member_ids_json': memberIdsJson,
    });
  }

  CachedTodosCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? priority,
      Value<bool>? completed,
      Value<DateTime?>? dueDate,
      Value<int?>? categoryId,
      Value<String?>? categoryName,
      Value<int?>? eventId,
      Value<int?>? parentId,
      Value<bool>? requiresMultiple,
      Value<String>? memberIdsJson}) {
    return CachedTodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      eventId: eventId ?? this.eventId,
      parentId: parentId ?? this.parentId,
      requiresMultiple: requiresMultiple ?? this.requiresMultiple,
      memberIdsJson: memberIdsJson ?? this.memberIdsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (requiresMultiple.present) {
      map['requires_multiple'] = Variable<bool>(requiresMultiple.value);
    }
    if (memberIdsJson.present) {
      map['member_ids_json'] = Variable<String>(memberIdsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('completed: $completed, ')
          ..write('dueDate: $dueDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('eventId: $eventId, ')
          ..write('parentId: $parentId, ')
          ..write('requiresMultiple: $requiresMultiple, ')
          ..write('memberIdsJson: $memberIdsJson')
          ..write(')'))
        .toString();
  }
}

class $CachedRecipesTable extends CachedRecipes
    with TableInfo<$CachedRecipesTable, CachedRecipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mittel'));
  static const VerificationMeta _prepTimeMeta =
      const VerificationMeta('prepTime');
  @override
  late final GeneratedColumn<int> prepTime = GeneratedColumn<int>(
      'prep_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCookidooMeta =
      const VerificationMeta('isCookidoo');
  @override
  late final GeneratedColumn<bool> isCookidoo = GeneratedColumn<bool>(
      'is_cookidoo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cookidoo" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _ingredientsJsonMeta =
      const VerificationMeta('ingredientsJson');
  @override
  late final GeneratedColumn<String> ingredientsJson = GeneratedColumn<String>(
      'ingredients_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        difficulty,
        prepTime,
        imageUrl,
        isCookidoo,
        ingredientsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_recipes';
  @override
  VerificationContext validateIntegrity(Insertable<CachedRecipe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('prep_time')) {
      context.handle(_prepTimeMeta,
          prepTime.isAcceptableOrUnknown(data['prep_time']!, _prepTimeMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('is_cookidoo')) {
      context.handle(
          _isCookidooMeta,
          isCookidoo.isAcceptableOrUnknown(
              data['is_cookidoo']!, _isCookidooMeta));
    }
    if (data.containsKey('ingredients_json')) {
      context.handle(
          _ingredientsJsonMeta,
          ingredientsJson.isAcceptableOrUnknown(
              data['ingredients_json']!, _ingredientsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedRecipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRecipe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      prepTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prep_time']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      isCookidoo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cookidoo'])!,
      ingredientsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ingredients_json'])!,
    );
  }

  @override
  $CachedRecipesTable createAlias(String alias) {
    return $CachedRecipesTable(attachedDatabase, alias);
  }
}

class CachedRecipe extends DataClass implements Insertable<CachedRecipe> {
  final int id;
  final String name;
  final String? description;
  final String difficulty;
  final int? prepTime;
  final String? imageUrl;
  final bool isCookidoo;
  final String ingredientsJson;
  const CachedRecipe(
      {required this.id,
      required this.name,
      this.description,
      required this.difficulty,
      this.prepTime,
      this.imageUrl,
      required this.isCookidoo,
      required this.ingredientsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['difficulty'] = Variable<String>(difficulty);
    if (!nullToAbsent || prepTime != null) {
      map['prep_time'] = Variable<int>(prepTime);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['is_cookidoo'] = Variable<bool>(isCookidoo);
    map['ingredients_json'] = Variable<String>(ingredientsJson);
    return map;
  }

  CachedRecipesCompanion toCompanion(bool nullToAbsent) {
    return CachedRecipesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      difficulty: Value(difficulty),
      prepTime: prepTime == null && nullToAbsent
          ? const Value.absent()
          : Value(prepTime),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      isCookidoo: Value(isCookidoo),
      ingredientsJson: Value(ingredientsJson),
    );
  }

  factory CachedRecipe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRecipe(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      prepTime: serializer.fromJson<int?>(json['prepTime']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      isCookidoo: serializer.fromJson<bool>(json['isCookidoo']),
      ingredientsJson: serializer.fromJson<String>(json['ingredientsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'difficulty': serializer.toJson<String>(difficulty),
      'prepTime': serializer.toJson<int?>(prepTime),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'isCookidoo': serializer.toJson<bool>(isCookidoo),
      'ingredientsJson': serializer.toJson<String>(ingredientsJson),
    };
  }

  CachedRecipe copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? difficulty,
          Value<int?> prepTime = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          bool? isCookidoo,
          String? ingredientsJson}) =>
      CachedRecipe(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        difficulty: difficulty ?? this.difficulty,
        prepTime: prepTime.present ? prepTime.value : this.prepTime,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        isCookidoo: isCookidoo ?? this.isCookidoo,
        ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      );
  CachedRecipe copyWithCompanion(CachedRecipesCompanion data) {
    return CachedRecipe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      prepTime: data.prepTime.present ? data.prepTime.value : this.prepTime,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isCookidoo:
          data.isCookidoo.present ? data.isCookidoo.value : this.isCookidoo,
      ingredientsJson: data.ingredientsJson.present
          ? data.ingredientsJson.value
          : this.ingredientsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecipe(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('prepTime: $prepTime, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isCookidoo: $isCookidoo, ')
          ..write('ingredientsJson: $ingredientsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, difficulty, prepTime,
      imageUrl, isCookidoo, ingredientsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRecipe &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.difficulty == this.difficulty &&
          other.prepTime == this.prepTime &&
          other.imageUrl == this.imageUrl &&
          other.isCookidoo == this.isCookidoo &&
          other.ingredientsJson == this.ingredientsJson);
}

class CachedRecipesCompanion extends UpdateCompanion<CachedRecipe> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> difficulty;
  final Value<int?> prepTime;
  final Value<String?> imageUrl;
  final Value<bool> isCookidoo;
  final Value<String> ingredientsJson;
  const CachedRecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isCookidoo = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
  });
  CachedRecipesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isCookidoo = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedRecipe> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? difficulty,
    Expression<int>? prepTime,
    Expression<String>? imageUrl,
    Expression<bool>? isCookidoo,
    Expression<String>? ingredientsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (difficulty != null) 'difficulty': difficulty,
      if (prepTime != null) 'prep_time': prepTime,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isCookidoo != null) 'is_cookidoo': isCookidoo,
      if (ingredientsJson != null) 'ingredients_json': ingredientsJson,
    });
  }

  CachedRecipesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? difficulty,
      Value<int?>? prepTime,
      Value<String?>? imageUrl,
      Value<bool>? isCookidoo,
      Value<String>? ingredientsJson}) {
    return CachedRecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      imageUrl: imageUrl ?? this.imageUrl,
      isCookidoo: isCookidoo ?? this.isCookidoo,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (prepTime.present) {
      map['prep_time'] = Variable<int>(prepTime.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isCookidoo.present) {
      map['is_cookidoo'] = Variable<bool>(isCookidoo.value);
    }
    if (ingredientsJson.present) {
      map['ingredients_json'] = Variable<String>(ingredientsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecipesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('prepTime: $prepTime, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isCookidoo: $isCookidoo, ')
          ..write('ingredientsJson: $ingredientsJson')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(Insertable<CachedCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final int id;
  final String name;
  final String? color;
  const CachedCategory({required this.id, required this.name, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory CachedCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
    };
  }

  CachedCategory copyWith(
          {int? id,
          String? name,
          Value<String?> color = const Value.absent()}) =>
      CachedCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
      );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> color;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  CachedCategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String?>? color}) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $CachedFamilyMembersTable extends CachedFamilyMembers
    with TableInfo<$CachedFamilyMembersTable, CachedFamilyMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFamilyMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, emoji, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_family_members';
  @override
  VerificationContext validateIntegrity(Insertable<CachedFamilyMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFamilyMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFamilyMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $CachedFamilyMembersTable createAlias(String alias) {
    return $CachedFamilyMembersTable(attachedDatabase, alias);
  }
}

class CachedFamilyMember extends DataClass
    implements Insertable<CachedFamilyMember> {
  final int id;
  final String name;
  final String? emoji;
  final String? color;
  const CachedFamilyMember(
      {required this.id, required this.name, this.emoji, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  CachedFamilyMembersCompanion toCompanion(bool nullToAbsent) {
    return CachedFamilyMembersCompanion(
      id: Value(id),
      name: Value(name),
      emoji:
          emoji == null && nullToAbsent ? const Value.absent() : Value(emoji),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory CachedFamilyMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFamilyMember(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String?>(emoji),
      'color': serializer.toJson<String?>(color),
    };
  }

  CachedFamilyMember copyWith(
          {int? id,
          String? name,
          Value<String?> emoji = const Value.absent(),
          Value<String?> color = const Value.absent()}) =>
      CachedFamilyMember(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji.present ? emoji.value : this.emoji,
        color: color.present ? color.value : this.color,
      );
  CachedFamilyMember copyWithCompanion(CachedFamilyMembersCompanion data) {
    return CachedFamilyMember(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFamilyMember(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFamilyMember &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.color == this.color);
}

class CachedFamilyMembersCompanion extends UpdateCompanion<CachedFamilyMember> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> emoji;
  final Value<String?> color;
  const CachedFamilyMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
  });
  CachedFamilyMembersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedFamilyMember> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
    });
  }

  CachedFamilyMembersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? emoji,
      Value<String?>? color}) {
    return CachedFamilyMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFamilyMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $CachedShoppingItemsTable extends CachedShoppingItems
    with TableInfo<$CachedShoppingItemsTable, CachedShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkedMeta =
      const VerificationMeta('checked');
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
      'checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isManualMeta =
      const VerificationMeta('isManual');
  @override
  late final GeneratedColumn<bool> isManual = GeneratedColumn<bool>(
      'is_manual', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_manual" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, amount, unit, checked, isManual, category, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_shopping_items';
  @override
  VerificationContext validateIntegrity(Insertable<CachedShoppingItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('checked')) {
      context.handle(_checkedMeta,
          checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta));
    }
    if (data.containsKey('is_manual')) {
      context.handle(_isManualMeta,
          isManual.isAcceptableOrUnknown(data['is_manual']!, _isManualMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedShoppingItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      checked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}checked'])!,
      isManual: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_manual'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
    );
  }

  @override
  $CachedShoppingItemsTable createAlias(String alias) {
    return $CachedShoppingItemsTable(attachedDatabase, alias);
  }
}

class CachedShoppingItem extends DataClass
    implements Insertable<CachedShoppingItem> {
  final int id;
  final String name;
  final double? amount;
  final String? unit;
  final bool checked;
  final bool isManual;
  final String? category;
  final int? sortOrder;
  const CachedShoppingItem(
      {required this.id,
      required this.name,
      this.amount,
      this.unit,
      required this.checked,
      required this.isManual,
      this.category,
      this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['checked'] = Variable<bool>(checked);
    map['is_manual'] = Variable<bool>(isManual);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    return map;
  }

  CachedShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedShoppingItemsCompanion(
      id: Value(id),
      name: Value(name),
      amount:
          amount == null && nullToAbsent ? const Value.absent() : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      checked: Value(checked),
      isManual: Value(isManual),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
    );
  }

  factory CachedShoppingItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedShoppingItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      checked: serializer.fromJson<bool>(json['checked']),
      isManual: serializer.fromJson<bool>(json['isManual']),
      category: serializer.fromJson<String?>(json['category']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<String?>(unit),
      'checked': serializer.toJson<bool>(checked),
      'isManual': serializer.toJson<bool>(isManual),
      'category': serializer.toJson<String?>(category),
      'sortOrder': serializer.toJson<int?>(sortOrder),
    };
  }

  CachedShoppingItem copyWith(
          {int? id,
          String? name,
          Value<double?> amount = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          bool? checked,
          bool? isManual,
          Value<String?> category = const Value.absent(),
          Value<int?> sortOrder = const Value.absent()}) =>
      CachedShoppingItem(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount.present ? amount.value : this.amount,
        unit: unit.present ? unit.value : this.unit,
        checked: checked ?? this.checked,
        isManual: isManual ?? this.isManual,
        category: category.present ? category.value : this.category,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
      );
  CachedShoppingItem copyWithCompanion(CachedShoppingItemsCompanion data) {
    return CachedShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      checked: data.checked.present ? data.checked.value : this.checked,
      isManual: data.isManual.present ? data.isManual.value : this.isManual,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedShoppingItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('checked: $checked, ')
          ..write('isManual: $isManual, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, amount, unit, checked, isManual, category, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedShoppingItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.checked == this.checked &&
          other.isManual == this.isManual &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder);
}

class CachedShoppingItemsCompanion extends UpdateCompanion<CachedShoppingItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> amount;
  final Value<String?> unit;
  final Value<bool> checked;
  final Value<bool> isManual;
  final Value<String?> category;
  final Value<int?> sortOrder;
  const CachedShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.checked = const Value.absent(),
    this.isManual = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CachedShoppingItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.checked = const Value.absent(),
    this.isManual = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedShoppingItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<bool>? checked,
    Expression<bool>? isManual,
    Expression<String>? category,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (checked != null) 'checked': checked,
      if (isManual != null) 'is_manual': isManual,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CachedShoppingItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double?>? amount,
      Value<String?>? unit,
      Value<bool>? checked,
      Value<bool>? isManual,
      Value<String?>? category,
      Value<int?>? sortOrder}) {
    return CachedShoppingItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      checked: checked ?? this.checked,
      isManual: isManual ?? this.isManual,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (isManual.present) {
      map['is_manual'] = Variable<bool>(isManual.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('checked: $checked, ')
          ..write('isManual: $isManual, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CachedPantryItemsTable extends CachedPantryItems
    with TableInfo<$CachedPantryItemsTable, CachedPantryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPantryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lowStockThresholdMeta =
      const VerificationMeta('lowStockThreshold');
  @override
  late final GeneratedColumn<int> lowStockThreshold = GeneratedColumn<int>(
      'low_stock_threshold', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, quantity, unit, category, expiryDate, lowStockThreshold];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pantry_items';
  @override
  VerificationContext validateIntegrity(Insertable<CachedPantryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
          _lowStockThresholdMeta,
          lowStockThreshold.isAcceptableOrUnknown(
              data['low_stock_threshold']!, _lowStockThresholdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPantryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPantryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date']),
      lowStockThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}low_stock_threshold']),
    );
  }

  @override
  $CachedPantryItemsTable createAlias(String alias) {
    return $CachedPantryItemsTable(attachedDatabase, alias);
  }
}

class CachedPantryItem extends DataClass
    implements Insertable<CachedPantryItem> {
  final int id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final DateTime? expiryDate;
  final int? lowStockThreshold;
  const CachedPantryItem(
      {required this.id,
      required this.name,
      this.quantity,
      this.unit,
      this.category,
      this.expiryDate,
      this.lowStockThreshold});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || lowStockThreshold != null) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold);
    }
    return map;
  }

  CachedPantryItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedPantryItemsCompanion(
      id: Value(id),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      lowStockThreshold: lowStockThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockThreshold),
    );
  }

  factory CachedPantryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPantryItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      category: serializer.fromJson<String?>(json['category']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      lowStockThreshold: serializer.fromJson<int?>(json['lowStockThreshold']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'category': serializer.toJson<String?>(category),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'lowStockThreshold': serializer.toJson<int?>(lowStockThreshold),
    };
  }

  CachedPantryItem copyWith(
          {int? id,
          String? name,
          Value<double?> quantity = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<DateTime?> expiryDate = const Value.absent(),
          Value<int?> lowStockThreshold = const Value.absent()}) =>
      CachedPantryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity.present ? quantity.value : this.quantity,
        unit: unit.present ? unit.value : this.unit,
        category: category.present ? category.value : this.category,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        lowStockThreshold: lowStockThreshold.present
            ? lowStockThreshold.value
            : this.lowStockThreshold,
      );
  CachedPantryItem copyWithCompanion(CachedPantryItemsCompanion data) {
    return CachedPantryItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      category: data.category.present ? data.category.value : this.category,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPantryItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lowStockThreshold: $lowStockThreshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, quantity, unit, category, expiryDate, lowStockThreshold);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPantryItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.category == this.category &&
          other.expiryDate == this.expiryDate &&
          other.lowStockThreshold == this.lowStockThreshold);
}

class CachedPantryItemsCompanion extends UpdateCompanion<CachedPantryItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String?> category;
  final Value<DateTime?> expiryDate;
  final Value<int?> lowStockThreshold;
  const CachedPantryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
  });
  CachedPantryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedPantryItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? category,
    Expression<DateTime>? expiryDate,
    Expression<int>? lowStockThreshold,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
    });
  }

  CachedPantryItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double?>? quantity,
      Value<String?>? unit,
      Value<String?>? category,
      Value<DateTime?>? expiryDate,
      Value<int?>? lowStockThreshold}) {
    return CachedPantryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPantryItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lowStockThreshold: $lowStockThreshold')
          ..write(')'))
        .toString();
  }
}

class $PendingChangesTable extends PendingChanges
    with TableInfo<$PendingChangesTable, PendingChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, action, endpoint, payloadJson, createdAt, retryCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_changes';
  @override
  VerificationContext validateIntegrity(Insertable<PendingChange> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingChange(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
    );
  }

  @override
  $PendingChangesTable createAlias(String alias) {
    return $PendingChangesTable(attachedDatabase, alias);
  }
}

class PendingChange extends DataClass implements Insertable<PendingChange> {
  final int id;
  final String action;
  final String endpoint;
  final String? payloadJson;
  final DateTime createdAt;
  final int retryCount;
  const PendingChange(
      {required this.id,
      required this.action,
      required this.endpoint,
      this.payloadJson,
      required this.createdAt,
      required this.retryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['endpoint'] = Variable<String>(endpoint);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  PendingChangesCompanion toCompanion(bool nullToAbsent) {
    return PendingChangesCompanion(
      id: Value(id),
      action: Value(action),
      endpoint: Value(endpoint),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory PendingChange.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingChange(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'endpoint': serializer.toJson<String>(endpoint),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  PendingChange copyWith(
          {int? id,
          String? action,
          String? endpoint,
          Value<String?> payloadJson = const Value.absent(),
          DateTime? createdAt,
          int? retryCount}) =>
      PendingChange(
        id: id ?? this.id,
        action: action ?? this.action,
        endpoint: endpoint ?? this.endpoint,
        payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
      );
  PendingChange copyWithCompanion(PendingChangesCompanion data) {
    return PendingChange(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingChange(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('endpoint: $endpoint, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, action, endpoint, payloadJson, createdAt, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingChange &&
          other.id == this.id &&
          other.action == this.action &&
          other.endpoint == this.endpoint &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class PendingChangesCompanion extends UpdateCompanion<PendingChange> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> endpoint;
  final Value<String?> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  const PendingChangesCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  PendingChangesCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String endpoint,
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  })  : action = Value(action),
        endpoint = Value(endpoint);
  static Insertable<PendingChange> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? endpoint,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (endpoint != null) 'endpoint': endpoint,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  PendingChangesCompanion copyWith(
      {Value<int>? id,
      Value<String>? action,
      Value<String>? endpoint,
      Value<String?>? payloadJson,
      Value<DateTime>? createdAt,
      Value<int>? retryCount}) {
    return PendingChangesCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      endpoint: endpoint ?? this.endpoint,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangesCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('endpoint: $endpoint, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEventsTable cachedEvents = $CachedEventsTable(this);
  late final $CachedTodosTable cachedTodos = $CachedTodosTable(this);
  late final $CachedRecipesTable cachedRecipes = $CachedRecipesTable(this);
  late final $CachedCategoriesTable cachedCategories =
      $CachedCategoriesTable(this);
  late final $CachedFamilyMembersTable cachedFamilyMembers =
      $CachedFamilyMembersTable(this);
  late final $CachedShoppingItemsTable cachedShoppingItems =
      $CachedShoppingItemsTable(this);
  late final $CachedPantryItemsTable cachedPantryItems =
      $CachedPantryItemsTable(this);
  late final $PendingChangesTable pendingChanges = $PendingChangesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedEvents,
        cachedTodos,
        cachedRecipes,
        cachedCategories,
        cachedFamilyMembers,
        cachedShoppingItems,
        cachedPantryItems,
        pendingChanges
      ];
}

typedef $$CachedEventsTableCreateCompanionBuilder = CachedEventsCompanion
    Function({
  Value<int> id,
  required String title,
  Value<String?> description,
  required DateTime startTime,
  required DateTime endTime,
  Value<bool> allDay,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<String?> categoryColor,
  Value<String> memberIdsJson,
  Value<String> membersJson,
});
typedef $$CachedEventsTableUpdateCompanionBuilder = CachedEventsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String?> description,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<bool> allDay,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<String?> categoryColor,
  Value<String> memberIdsJson,
  Value<String> membersJson,
});

class $$CachedEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryColor => $composableBuilder(
      column: $table.categoryColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnFilters(column));
}

class $$CachedEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryColor => $composableBuilder(
      column: $table.categoryColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnOrderings(column));
}

class $$CachedEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEventsTable> {
  $$CachedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get categoryColor => $composableBuilder(
      column: $table.categoryColor, builder: (column) => column);

  GeneratedColumn<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => column);

  GeneratedColumn<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => column);
}

class $$CachedEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedEventsTable,
    CachedEvent,
    $$CachedEventsTableFilterComposer,
    $$CachedEventsTableOrderingComposer,
    $$CachedEventsTableAnnotationComposer,
    $$CachedEventsTableCreateCompanionBuilder,
    $$CachedEventsTableUpdateCompanionBuilder,
    (
      CachedEvent,
      BaseReferences<_$AppDatabase, $CachedEventsTable, CachedEvent>
    ),
    CachedEvent,
    PrefetchHooks Function()> {
  $$CachedEventsTableTableManager(_$AppDatabase db, $CachedEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> categoryColor = const Value.absent(),
            Value<String> memberIdsJson = const Value.absent(),
            Value<String> membersJson = const Value.absent(),
          }) =>
              CachedEventsCompanion(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryColor: categoryColor,
            memberIdsJson: memberIdsJson,
            membersJson: membersJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            Value<bool> allDay = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> categoryColor = const Value.absent(),
            Value<String> memberIdsJson = const Value.absent(),
            Value<String> membersJson = const Value.absent(),
          }) =>
              CachedEventsCompanion.insert(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryColor: categoryColor,
            memberIdsJson: memberIdsJson,
            membersJson: membersJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedEventsTable,
    CachedEvent,
    $$CachedEventsTableFilterComposer,
    $$CachedEventsTableOrderingComposer,
    $$CachedEventsTableAnnotationComposer,
    $$CachedEventsTableCreateCompanionBuilder,
    $$CachedEventsTableUpdateCompanionBuilder,
    (
      CachedEvent,
      BaseReferences<_$AppDatabase, $CachedEventsTable, CachedEvent>
    ),
    CachedEvent,
    PrefetchHooks Function()>;
typedef $$CachedTodosTableCreateCompanionBuilder = CachedTodosCompanion
    Function({
  Value<int> id,
  required String title,
  Value<String?> description,
  Value<String> priority,
  Value<bool> completed,
  Value<DateTime?> dueDate,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<int?> eventId,
  Value<int?> parentId,
  Value<bool> requiresMultiple,
  Value<String> memberIdsJson,
});
typedef $$CachedTodosTableUpdateCompanionBuilder = CachedTodosCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String?> description,
  Value<String> priority,
  Value<bool> completed,
  Value<DateTime?> dueDate,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<int?> eventId,
  Value<int?> parentId,
  Value<bool> requiresMultiple,
  Value<String> memberIdsJson,
});

class $$CachedTodosTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTodosTable> {
  $$CachedTodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiresMultiple => $composableBuilder(
      column: $table.requiresMultiple,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => ColumnFilters(column));
}

class $$CachedTodosTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTodosTable> {
  $$CachedTodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiresMultiple => $composableBuilder(
      column: $table.requiresMultiple,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedTodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTodosTable> {
  $$CachedTodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<int> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<bool> get requiresMultiple => $composableBuilder(
      column: $table.requiresMultiple, builder: (column) => column);

  GeneratedColumn<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => column);
}

class $$CachedTodosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedTodosTable,
    CachedTodo,
    $$CachedTodosTableFilterComposer,
    $$CachedTodosTableOrderingComposer,
    $$CachedTodosTableAnnotationComposer,
    $$CachedTodosTableCreateCompanionBuilder,
    $$CachedTodosTableUpdateCompanionBuilder,
    (CachedTodo, BaseReferences<_$AppDatabase, $CachedTodosTable, CachedTodo>),
    CachedTodo,
    PrefetchHooks Function()> {
  $$CachedTodosTableTableManager(_$AppDatabase db, $CachedTodosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<int?> eventId = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<bool> requiresMultiple = const Value.absent(),
            Value<String> memberIdsJson = const Value.absent(),
          }) =>
              CachedTodosCompanion(
            id: id,
            title: title,
            description: description,
            priority: priority,
            completed: completed,
            dueDate: dueDate,
            categoryId: categoryId,
            categoryName: categoryName,
            eventId: eventId,
            parentId: parentId,
            requiresMultiple: requiresMultiple,
            memberIdsJson: memberIdsJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<int?> eventId = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<bool> requiresMultiple = const Value.absent(),
            Value<String> memberIdsJson = const Value.absent(),
          }) =>
              CachedTodosCompanion.insert(
            id: id,
            title: title,
            description: description,
            priority: priority,
            completed: completed,
            dueDate: dueDate,
            categoryId: categoryId,
            categoryName: categoryName,
            eventId: eventId,
            parentId: parentId,
            requiresMultiple: requiresMultiple,
            memberIdsJson: memberIdsJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedTodosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedTodosTable,
    CachedTodo,
    $$CachedTodosTableFilterComposer,
    $$CachedTodosTableOrderingComposer,
    $$CachedTodosTableAnnotationComposer,
    $$CachedTodosTableCreateCompanionBuilder,
    $$CachedTodosTableUpdateCompanionBuilder,
    (CachedTodo, BaseReferences<_$AppDatabase, $CachedTodosTable, CachedTodo>),
    CachedTodo,
    PrefetchHooks Function()>;
typedef $$CachedRecipesTableCreateCompanionBuilder = CachedRecipesCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  Value<String> difficulty,
  Value<int?> prepTime,
  Value<String?> imageUrl,
  Value<bool> isCookidoo,
  Value<String> ingredientsJson,
});
typedef $$CachedRecipesTableUpdateCompanionBuilder = CachedRecipesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<String> difficulty,
  Value<int?> prepTime,
  Value<String?> imageUrl,
  Value<bool> isCookidoo,
  Value<String> ingredientsJson,
});

class $$CachedRecipesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRecipesTable> {
  $$CachedRecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get prepTime => $composableBuilder(
      column: $table.prepTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCookidoo => $composableBuilder(
      column: $table.isCookidoo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ingredientsJson => $composableBuilder(
      column: $table.ingredientsJson,
      builder: (column) => ColumnFilters(column));
}

class $$CachedRecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRecipesTable> {
  $$CachedRecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get prepTime => $composableBuilder(
      column: $table.prepTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCookidoo => $composableBuilder(
      column: $table.isCookidoo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ingredientsJson => $composableBuilder(
      column: $table.ingredientsJson,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedRecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRecipesTable> {
  $$CachedRecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get prepTime =>
      $composableBuilder(column: $table.prepTime, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isCookidoo => $composableBuilder(
      column: $table.isCookidoo, builder: (column) => column);

  GeneratedColumn<String> get ingredientsJson => $composableBuilder(
      column: $table.ingredientsJson, builder: (column) => column);
}

class $$CachedRecipesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedRecipesTable,
    CachedRecipe,
    $$CachedRecipesTableFilterComposer,
    $$CachedRecipesTableOrderingComposer,
    $$CachedRecipesTableAnnotationComposer,
    $$CachedRecipesTableCreateCompanionBuilder,
    $$CachedRecipesTableUpdateCompanionBuilder,
    (
      CachedRecipe,
      BaseReferences<_$AppDatabase, $CachedRecipesTable, CachedRecipe>
    ),
    CachedRecipe,
    PrefetchHooks Function()> {
  $$CachedRecipesTableTableManager(_$AppDatabase db, $CachedRecipesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<bool> isCookidoo = const Value.absent(),
            Value<String> ingredientsJson = const Value.absent(),
          }) =>
              CachedRecipesCompanion(
            id: id,
            name: name,
            description: description,
            difficulty: difficulty,
            prepTime: prepTime,
            imageUrl: imageUrl,
            isCookidoo: isCookidoo,
            ingredientsJson: ingredientsJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<bool> isCookidoo = const Value.absent(),
            Value<String> ingredientsJson = const Value.absent(),
          }) =>
              CachedRecipesCompanion.insert(
            id: id,
            name: name,
            description: description,
            difficulty: difficulty,
            prepTime: prepTime,
            imageUrl: imageUrl,
            isCookidoo: isCookidoo,
            ingredientsJson: ingredientsJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedRecipesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedRecipesTable,
    CachedRecipe,
    $$CachedRecipesTableFilterComposer,
    $$CachedRecipesTableOrderingComposer,
    $$CachedRecipesTableAnnotationComposer,
    $$CachedRecipesTableCreateCompanionBuilder,
    $$CachedRecipesTableUpdateCompanionBuilder,
    (
      CachedRecipe,
      BaseReferences<_$AppDatabase, $CachedRecipesTable, CachedRecipe>
    ),
    CachedRecipe,
    PrefetchHooks Function()>;
typedef $$CachedCategoriesTableCreateCompanionBuilder
    = CachedCategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> color,
});
typedef $$CachedCategoriesTableUpdateCompanionBuilder
    = CachedCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> color,
});

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedCategoriesTable,
    CachedCategory,
    $$CachedCategoriesTableFilterComposer,
    $$CachedCategoriesTableOrderingComposer,
    $$CachedCategoriesTableAnnotationComposer,
    $$CachedCategoriesTableCreateCompanionBuilder,
    $$CachedCategoriesTableUpdateCompanionBuilder,
    (
      CachedCategory,
      BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>
    ),
    CachedCategory,
    PrefetchHooks Function()> {
  $$CachedCategoriesTableTableManager(
      _$AppDatabase db, $CachedCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              CachedCategoriesCompanion(
            id: id,
            name: name,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
          }) =>
              CachedCategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedCategoriesTable,
    CachedCategory,
    $$CachedCategoriesTableFilterComposer,
    $$CachedCategoriesTableOrderingComposer,
    $$CachedCategoriesTableAnnotationComposer,
    $$CachedCategoriesTableCreateCompanionBuilder,
    $$CachedCategoriesTableUpdateCompanionBuilder,
    (
      CachedCategory,
      BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>
    ),
    CachedCategory,
    PrefetchHooks Function()>;
typedef $$CachedFamilyMembersTableCreateCompanionBuilder
    = CachedFamilyMembersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> emoji,
  Value<String?> color,
});
typedef $$CachedFamilyMembersTableUpdateCompanionBuilder
    = CachedFamilyMembersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> emoji,
  Value<String?> color,
});

class $$CachedFamilyMembersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFamilyMembersTable> {
  $$CachedFamilyMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$CachedFamilyMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFamilyMembersTable> {
  $$CachedFamilyMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$CachedFamilyMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFamilyMembersTable> {
  $$CachedFamilyMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CachedFamilyMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedFamilyMembersTable,
    CachedFamilyMember,
    $$CachedFamilyMembersTableFilterComposer,
    $$CachedFamilyMembersTableOrderingComposer,
    $$CachedFamilyMembersTableAnnotationComposer,
    $$CachedFamilyMembersTableCreateCompanionBuilder,
    $$CachedFamilyMembersTableUpdateCompanionBuilder,
    (
      CachedFamilyMember,
      BaseReferences<_$AppDatabase, $CachedFamilyMembersTable,
          CachedFamilyMember>
    ),
    CachedFamilyMember,
    PrefetchHooks Function()> {
  $$CachedFamilyMembersTableTableManager(
      _$AppDatabase db, $CachedFamilyMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFamilyMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFamilyMembersTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFamilyMembersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> emoji = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              CachedFamilyMembersCompanion(
            id: id,
            name: name,
            emoji: emoji,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> emoji = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              CachedFamilyMembersCompanion.insert(
            id: id,
            name: name,
            emoji: emoji,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedFamilyMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedFamilyMembersTable,
    CachedFamilyMember,
    $$CachedFamilyMembersTableFilterComposer,
    $$CachedFamilyMembersTableOrderingComposer,
    $$CachedFamilyMembersTableAnnotationComposer,
    $$CachedFamilyMembersTableCreateCompanionBuilder,
    $$CachedFamilyMembersTableUpdateCompanionBuilder,
    (
      CachedFamilyMember,
      BaseReferences<_$AppDatabase, $CachedFamilyMembersTable,
          CachedFamilyMember>
    ),
    CachedFamilyMember,
    PrefetchHooks Function()>;
typedef $$CachedShoppingItemsTableCreateCompanionBuilder
    = CachedShoppingItemsCompanion Function({
  Value<int> id,
  required String name,
  Value<double?> amount,
  Value<String?> unit,
  Value<bool> checked,
  Value<bool> isManual,
  Value<String?> category,
  Value<int?> sortOrder,
});
typedef $$CachedShoppingItemsTableUpdateCompanionBuilder
    = CachedShoppingItemsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double?> amount,
  Value<String?> unit,
  Value<bool> checked,
  Value<bool> isManual,
  Value<String?> category,
  Value<int?> sortOrder,
});

class $$CachedShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedShoppingItemsTable> {
  $$CachedShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isManual => $composableBuilder(
      column: $table.isManual, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CachedShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedShoppingItemsTable> {
  $$CachedShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isManual => $composableBuilder(
      column: $table.isManual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CachedShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedShoppingItemsTable> {
  $$CachedShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<bool> get isManual =>
      $composableBuilder(column: $table.isManual, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CachedShoppingItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedShoppingItemsTable,
    CachedShoppingItem,
    $$CachedShoppingItemsTableFilterComposer,
    $$CachedShoppingItemsTableOrderingComposer,
    $$CachedShoppingItemsTableAnnotationComposer,
    $$CachedShoppingItemsTableCreateCompanionBuilder,
    $$CachedShoppingItemsTableUpdateCompanionBuilder,
    (
      CachedShoppingItem,
      BaseReferences<_$AppDatabase, $CachedShoppingItemsTable,
          CachedShoppingItem>
    ),
    CachedShoppingItem,
    PrefetchHooks Function()> {
  $$CachedShoppingItemsTableTableManager(
      _$AppDatabase db, $CachedShoppingItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedShoppingItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedShoppingItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<bool> checked = const Value.absent(),
            Value<bool> isManual = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
          }) =>
              CachedShoppingItemsCompanion(
            id: id,
            name: name,
            amount: amount,
            unit: unit,
            checked: checked,
            isManual: isManual,
            category: category,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<bool> checked = const Value.absent(),
            Value<bool> isManual = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
          }) =>
              CachedShoppingItemsCompanion.insert(
            id: id,
            name: name,
            amount: amount,
            unit: unit,
            checked: checked,
            isManual: isManual,
            category: category,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedShoppingItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedShoppingItemsTable,
    CachedShoppingItem,
    $$CachedShoppingItemsTableFilterComposer,
    $$CachedShoppingItemsTableOrderingComposer,
    $$CachedShoppingItemsTableAnnotationComposer,
    $$CachedShoppingItemsTableCreateCompanionBuilder,
    $$CachedShoppingItemsTableUpdateCompanionBuilder,
    (
      CachedShoppingItem,
      BaseReferences<_$AppDatabase, $CachedShoppingItemsTable,
          CachedShoppingItem>
    ),
    CachedShoppingItem,
    PrefetchHooks Function()>;
typedef $$CachedPantryItemsTableCreateCompanionBuilder
    = CachedPantryItemsCompanion Function({
  Value<int> id,
  required String name,
  Value<double?> quantity,
  Value<String?> unit,
  Value<String?> category,
  Value<DateTime?> expiryDate,
  Value<int?> lowStockThreshold,
});
typedef $$CachedPantryItemsTableUpdateCompanionBuilder
    = CachedPantryItemsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double?> quantity,
  Value<String?> unit,
  Value<String?> category,
  Value<DateTime?> expiryDate,
  Value<int?> lowStockThreshold,
});

class $$CachedPantryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPantryItemsTable> {
  $$CachedPantryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnFilters(column));
}

class $$CachedPantryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPantryItemsTable> {
  $$CachedPantryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedPantryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPantryItemsTable> {
  $$CachedPantryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<int> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold, builder: (column) => column);
}

class $$CachedPantryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedPantryItemsTable,
    CachedPantryItem,
    $$CachedPantryItemsTableFilterComposer,
    $$CachedPantryItemsTableOrderingComposer,
    $$CachedPantryItemsTableAnnotationComposer,
    $$CachedPantryItemsTableCreateCompanionBuilder,
    $$CachedPantryItemsTableUpdateCompanionBuilder,
    (
      CachedPantryItem,
      BaseReferences<_$AppDatabase, $CachedPantryItemsTable, CachedPantryItem>
    ),
    CachedPantryItem,
    PrefetchHooks Function()> {
  $$CachedPantryItemsTableTableManager(
      _$AppDatabase db, $CachedPantryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPantryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPantryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPantryItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<int?> lowStockThreshold = const Value.absent(),
          }) =>
              CachedPantryItemsCompanion(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            expiryDate: expiryDate,
            lowStockThreshold: lowStockThreshold,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<int?> lowStockThreshold = const Value.absent(),
          }) =>
              CachedPantryItemsCompanion.insert(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            expiryDate: expiryDate,
            lowStockThreshold: lowStockThreshold,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedPantryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedPantryItemsTable,
    CachedPantryItem,
    $$CachedPantryItemsTableFilterComposer,
    $$CachedPantryItemsTableOrderingComposer,
    $$CachedPantryItemsTableAnnotationComposer,
    $$CachedPantryItemsTableCreateCompanionBuilder,
    $$CachedPantryItemsTableUpdateCompanionBuilder,
    (
      CachedPantryItem,
      BaseReferences<_$AppDatabase, $CachedPantryItemsTable, CachedPantryItem>
    ),
    CachedPantryItem,
    PrefetchHooks Function()>;
typedef $$PendingChangesTableCreateCompanionBuilder = PendingChangesCompanion
    Function({
  Value<int> id,
  required String action,
  required String endpoint,
  Value<String?> payloadJson,
  Value<DateTime> createdAt,
  Value<int> retryCount,
});
typedef $$PendingChangesTableUpdateCompanionBuilder = PendingChangesCompanion
    Function({
  Value<int> id,
  Value<String> action,
  Value<String> endpoint,
  Value<String?> payloadJson,
  Value<DateTime> createdAt,
  Value<int> retryCount,
});

class $$PendingChangesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));
}

class $$PendingChangesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));
}

class $$PendingChangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);
}

class $$PendingChangesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingChangesTable,
    PendingChange,
    $$PendingChangesTableFilterComposer,
    $$PendingChangesTableOrderingComposer,
    $$PendingChangesTableAnnotationComposer,
    $$PendingChangesTableCreateCompanionBuilder,
    $$PendingChangesTableUpdateCompanionBuilder,
    (
      PendingChange,
      BaseReferences<_$AppDatabase, $PendingChangesTable, PendingChange>
    ),
    PendingChange,
    PrefetchHooks Function()> {
  $$PendingChangesTableTableManager(
      _$AppDatabase db, $PendingChangesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String?> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              PendingChangesCompanion(
            id: id,
            action: action,
            endpoint: endpoint,
            payloadJson: payloadJson,
            createdAt: createdAt,
            retryCount: retryCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String action,
            required String endpoint,
            Value<String?> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              PendingChangesCompanion.insert(
            id: id,
            action: action,
            endpoint: endpoint,
            payloadJson: payloadJson,
            createdAt: createdAt,
            retryCount: retryCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingChangesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingChangesTable,
    PendingChange,
    $$PendingChangesTableFilterComposer,
    $$PendingChangesTableOrderingComposer,
    $$PendingChangesTableAnnotationComposer,
    $$PendingChangesTableCreateCompanionBuilder,
    $$PendingChangesTableUpdateCompanionBuilder,
    (
      PendingChange,
      BaseReferences<_$AppDatabase, $PendingChangesTable, PendingChange>
    ),
    PendingChange,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEventsTableTableManager get cachedEvents =>
      $$CachedEventsTableTableManager(_db, _db.cachedEvents);
  $$CachedTodosTableTableManager get cachedTodos =>
      $$CachedTodosTableTableManager(_db, _db.cachedTodos);
  $$CachedRecipesTableTableManager get cachedRecipes =>
      $$CachedRecipesTableTableManager(_db, _db.cachedRecipes);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$CachedFamilyMembersTableTableManager get cachedFamilyMembers =>
      $$CachedFamilyMembersTableTableManager(_db, _db.cachedFamilyMembers);
  $$CachedShoppingItemsTableTableManager get cachedShoppingItems =>
      $$CachedShoppingItemsTableTableManager(_db, _db.cachedShoppingItems);
  $$CachedPantryItemsTableTableManager get cachedPantryItems =>
      $$CachedPantryItemsTableTableManager(_db, _db.cachedPantryItems);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(_db, _db.pendingChanges);
}
