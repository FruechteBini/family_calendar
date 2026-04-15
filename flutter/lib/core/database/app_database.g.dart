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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
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
        color,
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
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
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
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
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
  final String? color;
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
      this.color,
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
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
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
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
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
      color: serializer.fromJson<String?>(json['color']),
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
      'color': serializer.toJson<String?>(color),
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
          Value<String?> color = const Value.absent(),
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
        color: color.present ? color.value : this.color,
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
      color: data.color.present ? data.color.value : this.color,
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
          ..write('color: $color, ')
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
      color,
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
          other.color == this.color &&
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
  final Value<String?> color;
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
    this.color = const Value.absent(),
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
    this.color = const Value.absent(),
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
    Expression<String>? color,
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
      if (color != null) 'color': color,
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
      Value<String?>? color,
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
      color: color ?? this.color,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
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
          ..write('color: $color, ')
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
  static const VerificationMeta _recipeCategoryIdMeta =
      const VerificationMeta('recipeCategoryId');
  @override
  late final GeneratedColumn<int> recipeCategoryId = GeneratedColumn<int>(
      'recipe_category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recipeCategoryNameMeta =
      const VerificationMeta('recipeCategoryName');
  @override
  late final GeneratedColumn<String> recipeCategoryName =
      GeneratedColumn<String>('recipe_category_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
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
        ingredientsJson,
        recipeCategoryId,
        recipeCategoryName,
        tagsJson
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
    if (data.containsKey('recipe_category_id')) {
      context.handle(
          _recipeCategoryIdMeta,
          recipeCategoryId.isAcceptableOrUnknown(
              data['recipe_category_id']!, _recipeCategoryIdMeta));
    }
    if (data.containsKey('recipe_category_name')) {
      context.handle(
          _recipeCategoryNameMeta,
          recipeCategoryName.isAcceptableOrUnknown(
              data['recipe_category_name']!, _recipeCategoryNameMeta));
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
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
      recipeCategoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recipe_category_id']),
      recipeCategoryName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recipe_category_name']),
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
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
  final int? recipeCategoryId;
  final String? recipeCategoryName;
  final String tagsJson;
  const CachedRecipe(
      {required this.id,
      required this.name,
      this.description,
      required this.difficulty,
      this.prepTime,
      this.imageUrl,
      required this.isCookidoo,
      required this.ingredientsJson,
      this.recipeCategoryId,
      this.recipeCategoryName,
      required this.tagsJson});
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
    if (!nullToAbsent || recipeCategoryId != null) {
      map['recipe_category_id'] = Variable<int>(recipeCategoryId);
    }
    if (!nullToAbsent || recipeCategoryName != null) {
      map['recipe_category_name'] = Variable<String>(recipeCategoryName);
    }
    map['tags_json'] = Variable<String>(tagsJson);
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
      recipeCategoryId: recipeCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeCategoryId),
      recipeCategoryName: recipeCategoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeCategoryName),
      tagsJson: Value(tagsJson),
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
      recipeCategoryId: serializer.fromJson<int?>(json['recipeCategoryId']),
      recipeCategoryName:
          serializer.fromJson<String?>(json['recipeCategoryName']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
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
      'recipeCategoryId': serializer.toJson<int?>(recipeCategoryId),
      'recipeCategoryName': serializer.toJson<String?>(recipeCategoryName),
      'tagsJson': serializer.toJson<String>(tagsJson),
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
          String? ingredientsJson,
          Value<int?> recipeCategoryId = const Value.absent(),
          Value<String?> recipeCategoryName = const Value.absent(),
          String? tagsJson}) =>
      CachedRecipe(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        difficulty: difficulty ?? this.difficulty,
        prepTime: prepTime.present ? prepTime.value : this.prepTime,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        isCookidoo: isCookidoo ?? this.isCookidoo,
        ingredientsJson: ingredientsJson ?? this.ingredientsJson,
        recipeCategoryId: recipeCategoryId.present
            ? recipeCategoryId.value
            : this.recipeCategoryId,
        recipeCategoryName: recipeCategoryName.present
            ? recipeCategoryName.value
            : this.recipeCategoryName,
        tagsJson: tagsJson ?? this.tagsJson,
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
      recipeCategoryId: data.recipeCategoryId.present
          ? data.recipeCategoryId.value
          : this.recipeCategoryId,
      recipeCategoryName: data.recipeCategoryName.present
          ? data.recipeCategoryName.value
          : this.recipeCategoryName,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
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
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('recipeCategoryId: $recipeCategoryId, ')
          ..write('recipeCategoryName: $recipeCategoryName, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      difficulty,
      prepTime,
      imageUrl,
      isCookidoo,
      ingredientsJson,
      recipeCategoryId,
      recipeCategoryName,
      tagsJson);
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
          other.ingredientsJson == this.ingredientsJson &&
          other.recipeCategoryId == this.recipeCategoryId &&
          other.recipeCategoryName == this.recipeCategoryName &&
          other.tagsJson == this.tagsJson);
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
  final Value<int?> recipeCategoryId;
  final Value<String?> recipeCategoryName;
  final Value<String> tagsJson;
  const CachedRecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isCookidoo = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
    this.recipeCategoryId = const Value.absent(),
    this.recipeCategoryName = const Value.absent(),
    this.tagsJson = const Value.absent(),
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
    this.recipeCategoryId = const Value.absent(),
    this.recipeCategoryName = const Value.absent(),
    this.tagsJson = const Value.absent(),
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
    Expression<int>? recipeCategoryId,
    Expression<String>? recipeCategoryName,
    Expression<String>? tagsJson,
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
      if (recipeCategoryId != null) 'recipe_category_id': recipeCategoryId,
      if (recipeCategoryName != null)
        'recipe_category_name': recipeCategoryName,
      if (tagsJson != null) 'tags_json': tagsJson,
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
      Value<String>? ingredientsJson,
      Value<int?>? recipeCategoryId,
      Value<String?>? recipeCategoryName,
      Value<String>? tagsJson}) {
    return CachedRecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      imageUrl: imageUrl ?? this.imageUrl,
      isCookidoo: isCookidoo ?? this.isCookidoo,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      recipeCategoryId: recipeCategoryId ?? this.recipeCategoryId,
      recipeCategoryName: recipeCategoryName ?? this.recipeCategoryName,
      tagsJson: tagsJson ?? this.tagsJson,
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
    if (recipeCategoryId.present) {
      map['recipe_category_id'] = Variable<int>(recipeCategoryId.value);
    }
    if (recipeCategoryName.present) {
      map['recipe_category_name'] = Variable<String>(recipeCategoryName.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
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
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('recipeCategoryId: $recipeCategoryId, ')
          ..write('recipeCategoryName: $recipeCategoryName, ')
          ..write('tagsJson: $tagsJson')
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

class $CachedRecipeCategoriesTable extends CachedRecipeCategories
    with TableInfo<$CachedRecipeCategoriesTable, CachedRecipeCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRecipeCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, color, icon, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_recipe_categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<CachedRecipeCategory> instance,
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
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedRecipeCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRecipeCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $CachedRecipeCategoriesTable createAlias(String alias) {
    return $CachedRecipeCategoriesTable(attachedDatabase, alias);
  }
}

class CachedRecipeCategory extends DataClass
    implements Insertable<CachedRecipeCategory> {
  final int id;
  final String name;
  final String? color;
  final String? icon;
  final int position;
  const CachedRecipeCategory(
      {required this.id,
      required this.name,
      this.color,
      this.icon,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedRecipeCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedRecipeCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      position: Value(position),
    );
  }

  factory CachedRecipeCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRecipeCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedRecipeCategory copyWith(
          {int? id,
          String? name,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          int? position}) =>
      CachedRecipeCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        position: position ?? this.position,
      );
  CachedRecipeCategory copyWithCompanion(CachedRecipeCategoriesCompanion data) {
    return CachedRecipeCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecipeCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRecipeCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.position == this.position);
}

class CachedRecipeCategoriesCompanion
    extends UpdateCompanion<CachedRecipeCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<int> position;
  const CachedRecipeCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
  });
  CachedRecipeCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedRecipeCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (position != null) 'position': position,
    });
  }

  CachedRecipeCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? color,
      Value<String?>? icon,
      Value<int>? position}) {
    return CachedRecipeCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      position: position ?? this.position,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecipeCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('position: $position')
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

class $CachedNotesTable extends CachedNotes
    with TableInfo<$CachedNotesTable, CachedNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkTitleMeta =
      const VerificationMeta('linkTitle');
  @override
  late final GeneratedColumn<String> linkTitle = GeneratedColumn<String>(
      'link_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkThumbnailUrlMeta =
      const VerificationMeta('linkThumbnailUrl');
  @override
  late final GeneratedColumn<String> linkThumbnailUrl = GeneratedColumn<String>(
      'link_thumbnail_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkDomainMeta =
      const VerificationMeta('linkDomain');
  @override
  late final GeneratedColumn<String> linkDomain = GeneratedColumn<String>(
      'link_domain', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checklistJsonMeta =
      const VerificationMeta('checklistJson');
  @override
  late final GeneratedColumn<String> checklistJson = GeneratedColumn<String>(
      'checklist_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reminderAtMeta =
      const VerificationMeta('reminderAt');
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
      'reminder_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isPersonalMeta =
      const VerificationMeta('isPersonal');
  @override
  late final GeneratedColumn<bool> isPersonal = GeneratedColumn<bool>(
      'is_personal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_personal" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        type,
        content,
        url,
        linkTitle,
        linkThumbnailUrl,
        linkDomain,
        checklistJson,
        isPinned,
        isArchived,
        color,
        categoryId,
        categoryName,
        tagsJson,
        position,
        reminderAt,
        isPersonal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notes';
  @override
  VerificationContext validateIntegrity(Insertable<CachedNote> instance,
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('link_title')) {
      context.handle(_linkTitleMeta,
          linkTitle.isAcceptableOrUnknown(data['link_title']!, _linkTitleMeta));
    }
    if (data.containsKey('link_thumbnail_url')) {
      context.handle(
          _linkThumbnailUrlMeta,
          linkThumbnailUrl.isAcceptableOrUnknown(
              data['link_thumbnail_url']!, _linkThumbnailUrlMeta));
    }
    if (data.containsKey('link_domain')) {
      context.handle(
          _linkDomainMeta,
          linkDomain.isAcceptableOrUnknown(
              data['link_domain']!, _linkDomainMeta));
    }
    if (data.containsKey('checklist_json')) {
      context.handle(
          _checklistJsonMeta,
          checklistJson.isAcceptableOrUnknown(
              data['checklist_json']!, _checklistJsonMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
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
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
          _reminderAtMeta,
          reminderAt.isAcceptableOrUnknown(
              data['reminder_at']!, _reminderAtMeta));
    }
    if (data.containsKey('is_personal')) {
      context.handle(
          _isPersonalMeta,
          isPersonal.isAcceptableOrUnknown(
              data['is_personal']!, _isPersonalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      linkTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link_title']),
      linkThumbnailUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}link_thumbnail_url']),
      linkDomain: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link_domain']),
      checklistJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checklist_json']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      reminderAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reminder_at']),
      isPersonal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_personal'])!,
    );
  }

  @override
  $CachedNotesTable createAlias(String alias) {
    return $CachedNotesTable(attachedDatabase, alias);
  }
}

class CachedNote extends DataClass implements Insertable<CachedNote> {
  final int id;
  final String title;
  final String type;
  final String? content;
  final String? url;
  final String? linkTitle;
  final String? linkThumbnailUrl;
  final String? linkDomain;
  final String? checklistJson;
  final bool isPinned;
  final bool isArchived;
  final String? color;
  final int? categoryId;
  final String? categoryName;
  final String tagsJson;
  final int position;
  final DateTime? reminderAt;
  final bool isPersonal;
  const CachedNote(
      {required this.id,
      required this.title,
      required this.type,
      this.content,
      this.url,
      this.linkTitle,
      this.linkThumbnailUrl,
      this.linkDomain,
      this.checklistJson,
      required this.isPinned,
      required this.isArchived,
      this.color,
      this.categoryId,
      this.categoryName,
      required this.tagsJson,
      required this.position,
      this.reminderAt,
      required this.isPersonal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || linkTitle != null) {
      map['link_title'] = Variable<String>(linkTitle);
    }
    if (!nullToAbsent || linkThumbnailUrl != null) {
      map['link_thumbnail_url'] = Variable<String>(linkThumbnailUrl);
    }
    if (!nullToAbsent || linkDomain != null) {
      map['link_domain'] = Variable<String>(linkDomain);
    }
    if (!nullToAbsent || checklistJson != null) {
      map['checklist_json'] = Variable<String>(checklistJson);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    map['is_personal'] = Variable<bool>(isPersonal);
    return map;
  }

  CachedNotesCompanion toCompanion(bool nullToAbsent) {
    return CachedNotesCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      linkTitle: linkTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(linkTitle),
      linkThumbnailUrl: linkThumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(linkThumbnailUrl),
      linkDomain: linkDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(linkDomain),
      checklistJson: checklistJson == null && nullToAbsent
          ? const Value.absent()
          : Value(checklistJson),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      tagsJson: Value(tagsJson),
      position: Value(position),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      isPersonal: Value(isPersonal),
    );
  }

  factory CachedNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNote(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      url: serializer.fromJson<String?>(json['url']),
      linkTitle: serializer.fromJson<String?>(json['linkTitle']),
      linkThumbnailUrl: serializer.fromJson<String?>(json['linkThumbnailUrl']),
      linkDomain: serializer.fromJson<String?>(json['linkDomain']),
      checklistJson: serializer.fromJson<String?>(json['checklistJson']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      color: serializer.fromJson<String?>(json['color']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      position: serializer.fromJson<int>(json['position']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      isPersonal: serializer.fromJson<bool>(json['isPersonal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'url': serializer.toJson<String?>(url),
      'linkTitle': serializer.toJson<String?>(linkTitle),
      'linkThumbnailUrl': serializer.toJson<String?>(linkThumbnailUrl),
      'linkDomain': serializer.toJson<String?>(linkDomain),
      'checklistJson': serializer.toJson<String?>(checklistJson),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'color': serializer.toJson<String?>(color),
      'categoryId': serializer.toJson<int?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'position': serializer.toJson<int>(position),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'isPersonal': serializer.toJson<bool>(isPersonal),
    };
  }

  CachedNote copyWith(
          {int? id,
          String? title,
          String? type,
          Value<String?> content = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> linkTitle = const Value.absent(),
          Value<String?> linkThumbnailUrl = const Value.absent(),
          Value<String?> linkDomain = const Value.absent(),
          Value<String?> checklistJson = const Value.absent(),
          bool? isPinned,
          bool? isArchived,
          Value<String?> color = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          String? tagsJson,
          int? position,
          Value<DateTime?> reminderAt = const Value.absent(),
          bool? isPersonal}) =>
      CachedNote(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
        url: url.present ? url.value : this.url,
        linkTitle: linkTitle.present ? linkTitle.value : this.linkTitle,
        linkThumbnailUrl: linkThumbnailUrl.present
            ? linkThumbnailUrl.value
            : this.linkThumbnailUrl,
        linkDomain: linkDomain.present ? linkDomain.value : this.linkDomain,
        checklistJson:
            checklistJson.present ? checklistJson.value : this.checklistJson,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        color: color.present ? color.value : this.color,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        tagsJson: tagsJson ?? this.tagsJson,
        position: position ?? this.position,
        reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
        isPersonal: isPersonal ?? this.isPersonal,
      );
  CachedNote copyWithCompanion(CachedNotesCompanion data) {
    return CachedNote(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      url: data.url.present ? data.url.value : this.url,
      linkTitle: data.linkTitle.present ? data.linkTitle.value : this.linkTitle,
      linkThumbnailUrl: data.linkThumbnailUrl.present
          ? data.linkThumbnailUrl.value
          : this.linkThumbnailUrl,
      linkDomain:
          data.linkDomain.present ? data.linkDomain.value : this.linkDomain,
      checklistJson: data.checklistJson.present
          ? data.checklistJson.value
          : this.checklistJson,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      color: data.color.present ? data.color.value : this.color,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      position: data.position.present ? data.position.value : this.position,
      reminderAt:
          data.reminderAt.present ? data.reminderAt.value : this.reminderAt,
      isPersonal:
          data.isPersonal.present ? data.isPersonal.value : this.isPersonal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNote(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('url: $url, ')
          ..write('linkTitle: $linkTitle, ')
          ..write('linkThumbnailUrl: $linkThumbnailUrl, ')
          ..write('linkDomain: $linkDomain, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('color: $color, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('position: $position, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('isPersonal: $isPersonal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      type,
      content,
      url,
      linkTitle,
      linkThumbnailUrl,
      linkDomain,
      checklistJson,
      isPinned,
      isArchived,
      color,
      categoryId,
      categoryName,
      tagsJson,
      position,
      reminderAt,
      isPersonal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNote &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.content == this.content &&
          other.url == this.url &&
          other.linkTitle == this.linkTitle &&
          other.linkThumbnailUrl == this.linkThumbnailUrl &&
          other.linkDomain == this.linkDomain &&
          other.checklistJson == this.checklistJson &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.color == this.color &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.tagsJson == this.tagsJson &&
          other.position == this.position &&
          other.reminderAt == this.reminderAt &&
          other.isPersonal == this.isPersonal);
}

class CachedNotesCompanion extends UpdateCompanion<CachedNote> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> url;
  final Value<String?> linkTitle;
  final Value<String?> linkThumbnailUrl;
  final Value<String?> linkDomain;
  final Value<String?> checklistJson;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<String?> color;
  final Value<int?> categoryId;
  final Value<String?> categoryName;
  final Value<String> tagsJson;
  final Value<int> position;
  final Value<DateTime?> reminderAt;
  final Value<bool> isPersonal;
  const CachedNotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.url = const Value.absent(),
    this.linkTitle = const Value.absent(),
    this.linkThumbnailUrl = const Value.absent(),
    this.linkDomain = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.color = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.position = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.isPersonal = const Value.absent(),
  });
  CachedNotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.url = const Value.absent(),
    this.linkTitle = const Value.absent(),
    this.linkThumbnailUrl = const Value.absent(),
    this.linkDomain = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.color = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.position = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.isPersonal = const Value.absent(),
  }) : title = Value(title);
  static Insertable<CachedNote> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? url,
    Expression<String>? linkTitle,
    Expression<String>? linkThumbnailUrl,
    Expression<String>? linkDomain,
    Expression<String>? checklistJson,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<String>? color,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? tagsJson,
    Expression<int>? position,
    Expression<DateTime>? reminderAt,
    Expression<bool>? isPersonal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (url != null) 'url': url,
      if (linkTitle != null) 'link_title': linkTitle,
      if (linkThumbnailUrl != null) 'link_thumbnail_url': linkThumbnailUrl,
      if (linkDomain != null) 'link_domain': linkDomain,
      if (checklistJson != null) 'checklist_json': checklistJson,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (color != null) 'color': color,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (position != null) 'position': position,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (isPersonal != null) 'is_personal': isPersonal,
    });
  }

  CachedNotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? type,
      Value<String?>? content,
      Value<String?>? url,
      Value<String?>? linkTitle,
      Value<String?>? linkThumbnailUrl,
      Value<String?>? linkDomain,
      Value<String?>? checklistJson,
      Value<bool>? isPinned,
      Value<bool>? isArchived,
      Value<String?>? color,
      Value<int?>? categoryId,
      Value<String?>? categoryName,
      Value<String>? tagsJson,
      Value<int>? position,
      Value<DateTime?>? reminderAt,
      Value<bool>? isPersonal}) {
    return CachedNotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      url: url ?? this.url,
      linkTitle: linkTitle ?? this.linkTitle,
      linkThumbnailUrl: linkThumbnailUrl ?? this.linkThumbnailUrl,
      linkDomain: linkDomain ?? this.linkDomain,
      checklistJson: checklistJson ?? this.checklistJson,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tagsJson: tagsJson ?? this.tagsJson,
      position: position ?? this.position,
      reminderAt: reminderAt ?? this.reminderAt,
      isPersonal: isPersonal ?? this.isPersonal,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (linkTitle.present) {
      map['link_title'] = Variable<String>(linkTitle.value);
    }
    if (linkThumbnailUrl.present) {
      map['link_thumbnail_url'] = Variable<String>(linkThumbnailUrl.value);
    }
    if (linkDomain.present) {
      map['link_domain'] = Variable<String>(linkDomain.value);
    }
    if (checklistJson.present) {
      map['checklist_json'] = Variable<String>(checklistJson.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (isPersonal.present) {
      map['is_personal'] = Variable<bool>(isPersonal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('url: $url, ')
          ..write('linkTitle: $linkTitle, ')
          ..write('linkThumbnailUrl: $linkThumbnailUrl, ')
          ..write('linkDomain: $linkDomain, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('color: $color, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('position: $position, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('isPersonal: $isPersonal')
          ..write(')'))
        .toString();
  }
}

class $CachedNoteCategoriesTable extends CachedNoteCategories
    with TableInfo<$CachedNoteCategoriesTable, CachedNoteCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNoteCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, color, icon, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_note_categories';
  @override
  VerificationContext validateIntegrity(Insertable<CachedNoteCategory> instance,
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
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNoteCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNoteCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $CachedNoteCategoriesTable createAlias(String alias) {
    return $CachedNoteCategoriesTable(attachedDatabase, alias);
  }
}

class CachedNoteCategory extends DataClass
    implements Insertable<CachedNoteCategory> {
  final int id;
  final String name;
  final String? color;
  final String? icon;
  final int position;
  const CachedNoteCategory(
      {required this.id,
      required this.name,
      this.color,
      this.icon,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedNoteCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedNoteCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      position: Value(position),
    );
  }

  factory CachedNoteCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNoteCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedNoteCategory copyWith(
          {int? id,
          String? name,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          int? position}) =>
      CachedNoteCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        position: position ?? this.position,
      );
  CachedNoteCategory copyWithCompanion(CachedNoteCategoriesCompanion data) {
    return CachedNoteCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNoteCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNoteCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.position == this.position);
}

class CachedNoteCategoriesCompanion
    extends UpdateCompanion<CachedNoteCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<int> position;
  const CachedNoteCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
  });
  CachedNoteCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CachedNoteCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (position != null) 'position': position,
    });
  }

  CachedNoteCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? color,
      Value<String?>? icon,
      Value<int>? position}) {
    return CachedNoteCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      position: position ?? this.position,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNoteCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('position: $position')
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
  late final $CachedRecipeCategoriesTable cachedRecipeCategories =
      $CachedRecipeCategoriesTable(this);
  late final $CachedFamilyMembersTable cachedFamilyMembers =
      $CachedFamilyMembersTable(this);
  late final $CachedShoppingItemsTable cachedShoppingItems =
      $CachedShoppingItemsTable(this);
  late final $CachedPantryItemsTable cachedPantryItems =
      $CachedPantryItemsTable(this);
  late final $CachedNotesTable cachedNotes = $CachedNotesTable(this);
  late final $CachedNoteCategoriesTable cachedNoteCategories =
      $CachedNoteCategoriesTable(this);
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
        cachedRecipeCategories,
        cachedFamilyMembers,
        cachedShoppingItems,
        cachedPantryItems,
        cachedNotes,
        cachedNoteCategories,
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
  Value<String?> color,
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
  Value<String?> color,
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

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

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
            Value<String?> color = const Value.absent(),
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
            color: color,
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
            Value<String?> color = const Value.absent(),
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
            color: color,
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
  Value<int?> recipeCategoryId,
  Value<String?> recipeCategoryName,
  Value<String> tagsJson,
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
  Value<int?> recipeCategoryId,
  Value<String?> recipeCategoryName,
  Value<String> tagsJson,
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

  ColumnFilters<int> get recipeCategoryId => $composableBuilder(
      column: $table.recipeCategoryId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeCategoryName => $composableBuilder(
      column: $table.recipeCategoryName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<int> get recipeCategoryId => $composableBuilder(
      column: $table.recipeCategoryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeCategoryName => $composableBuilder(
      column: $table.recipeCategoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<int> get recipeCategoryId => $composableBuilder(
      column: $table.recipeCategoryId, builder: (column) => column);

  GeneratedColumn<String> get recipeCategoryName => $composableBuilder(
      column: $table.recipeCategoryName, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);
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
            Value<int?> recipeCategoryId = const Value.absent(),
            Value<String?> recipeCategoryName = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
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
            recipeCategoryId: recipeCategoryId,
            recipeCategoryName: recipeCategoryName,
            tagsJson: tagsJson,
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
            Value<int?> recipeCategoryId = const Value.absent(),
            Value<String?> recipeCategoryName = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
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
            recipeCategoryId: recipeCategoryId,
            recipeCategoryName: recipeCategoryName,
            tagsJson: tagsJson,
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
typedef $$CachedRecipeCategoriesTableCreateCompanionBuilder
    = CachedRecipeCategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> color,
  Value<String?> icon,
  Value<int> position,
});
typedef $$CachedRecipeCategoriesTableUpdateCompanionBuilder
    = CachedRecipeCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> color,
  Value<String?> icon,
  Value<int> position,
});

class $$CachedRecipeCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRecipeCategoriesTable> {
  $$CachedRecipeCategoriesTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$CachedRecipeCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRecipeCategoriesTable> {
  $$CachedRecipeCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$CachedRecipeCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRecipeCategoriesTable> {
  $$CachedRecipeCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedRecipeCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedRecipeCategoriesTable,
    CachedRecipeCategory,
    $$CachedRecipeCategoriesTableFilterComposer,
    $$CachedRecipeCategoriesTableOrderingComposer,
    $$CachedRecipeCategoriesTableAnnotationComposer,
    $$CachedRecipeCategoriesTableCreateCompanionBuilder,
    $$CachedRecipeCategoriesTableUpdateCompanionBuilder,
    (
      CachedRecipeCategory,
      BaseReferences<_$AppDatabase, $CachedRecipeCategoriesTable,
          CachedRecipeCategory>
    ),
    CachedRecipeCategory,
    PrefetchHooks Function()> {
  $$CachedRecipeCategoriesTableTableManager(
      _$AppDatabase db, $CachedRecipeCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRecipeCategoriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRecipeCategoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRecipeCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              CachedRecipeCategoriesCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            position: position,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              CachedRecipeCategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            position: position,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedRecipeCategoriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CachedRecipeCategoriesTable,
        CachedRecipeCategory,
        $$CachedRecipeCategoriesTableFilterComposer,
        $$CachedRecipeCategoriesTableOrderingComposer,
        $$CachedRecipeCategoriesTableAnnotationComposer,
        $$CachedRecipeCategoriesTableCreateCompanionBuilder,
        $$CachedRecipeCategoriesTableUpdateCompanionBuilder,
        (
          CachedRecipeCategory,
          BaseReferences<_$AppDatabase, $CachedRecipeCategoriesTable,
              CachedRecipeCategory>
        ),
        CachedRecipeCategory,
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
typedef $$CachedNotesTableCreateCompanionBuilder = CachedNotesCompanion
    Function({
  Value<int> id,
  required String title,
  Value<String> type,
  Value<String?> content,
  Value<String?> url,
  Value<String?> linkTitle,
  Value<String?> linkThumbnailUrl,
  Value<String?> linkDomain,
  Value<String?> checklistJson,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<String?> color,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<String> tagsJson,
  Value<int> position,
  Value<DateTime?> reminderAt,
  Value<bool> isPersonal,
});
typedef $$CachedNotesTableUpdateCompanionBuilder = CachedNotesCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String> type,
  Value<String?> content,
  Value<String?> url,
  Value<String?> linkTitle,
  Value<String?> linkThumbnailUrl,
  Value<String?> linkDomain,
  Value<String?> checklistJson,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<String?> color,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<String> tagsJson,
  Value<int> position,
  Value<DateTime?> reminderAt,
  Value<bool> isPersonal,
});

class $$CachedNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkTitle => $composableBuilder(
      column: $table.linkTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkThumbnailUrl => $composableBuilder(
      column: $table.linkThumbnailUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkDomain => $composableBuilder(
      column: $table.linkDomain, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPersonal => $composableBuilder(
      column: $table.isPersonal, builder: (column) => ColumnFilters(column));
}

class $$CachedNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkTitle => $composableBuilder(
      column: $table.linkTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkThumbnailUrl => $composableBuilder(
      column: $table.linkThumbnailUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkDomain => $composableBuilder(
      column: $table.linkDomain, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPersonal => $composableBuilder(
      column: $table.isPersonal, builder: (column) => ColumnOrderings(column));
}

class $$CachedNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get linkTitle =>
      $composableBuilder(column: $table.linkTitle, builder: (column) => column);

  GeneratedColumn<String> get linkThumbnailUrl => $composableBuilder(
      column: $table.linkThumbnailUrl, builder: (column) => column);

  GeneratedColumn<String> get linkDomain => $composableBuilder(
      column: $table.linkDomain, builder: (column) => column);

  GeneratedColumn<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => column);

  GeneratedColumn<bool> get isPersonal => $composableBuilder(
      column: $table.isPersonal, builder: (column) => column);
}

class $$CachedNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedNotesTable,
    CachedNote,
    $$CachedNotesTableFilterComposer,
    $$CachedNotesTableOrderingComposer,
    $$CachedNotesTableAnnotationComposer,
    $$CachedNotesTableCreateCompanionBuilder,
    $$CachedNotesTableUpdateCompanionBuilder,
    (CachedNote, BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>),
    CachedNote,
    PrefetchHooks Function()> {
  $$CachedNotesTableTableManager(_$AppDatabase db, $CachedNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> linkTitle = const Value.absent(),
            Value<String?> linkThumbnailUrl = const Value.absent(),
            Value<String?> linkDomain = const Value.absent(),
            Value<String?> checklistJson = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime?> reminderAt = const Value.absent(),
            Value<bool> isPersonal = const Value.absent(),
          }) =>
              CachedNotesCompanion(
            id: id,
            title: title,
            type: type,
            content: content,
            url: url,
            linkTitle: linkTitle,
            linkThumbnailUrl: linkThumbnailUrl,
            linkDomain: linkDomain,
            checklistJson: checklistJson,
            isPinned: isPinned,
            isArchived: isArchived,
            color: color,
            categoryId: categoryId,
            categoryName: categoryName,
            tagsJson: tagsJson,
            position: position,
            reminderAt: reminderAt,
            isPersonal: isPersonal,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> type = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> linkTitle = const Value.absent(),
            Value<String?> linkThumbnailUrl = const Value.absent(),
            Value<String?> linkDomain = const Value.absent(),
            Value<String?> checklistJson = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime?> reminderAt = const Value.absent(),
            Value<bool> isPersonal = const Value.absent(),
          }) =>
              CachedNotesCompanion.insert(
            id: id,
            title: title,
            type: type,
            content: content,
            url: url,
            linkTitle: linkTitle,
            linkThumbnailUrl: linkThumbnailUrl,
            linkDomain: linkDomain,
            checklistJson: checklistJson,
            isPinned: isPinned,
            isArchived: isArchived,
            color: color,
            categoryId: categoryId,
            categoryName: categoryName,
            tagsJson: tagsJson,
            position: position,
            reminderAt: reminderAt,
            isPersonal: isPersonal,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedNotesTable,
    CachedNote,
    $$CachedNotesTableFilterComposer,
    $$CachedNotesTableOrderingComposer,
    $$CachedNotesTableAnnotationComposer,
    $$CachedNotesTableCreateCompanionBuilder,
    $$CachedNotesTableUpdateCompanionBuilder,
    (CachedNote, BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>),
    CachedNote,
    PrefetchHooks Function()>;
typedef $$CachedNoteCategoriesTableCreateCompanionBuilder
    = CachedNoteCategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> color,
  Value<String?> icon,
  Value<int> position,
});
typedef $$CachedNoteCategoriesTableUpdateCompanionBuilder
    = CachedNoteCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> color,
  Value<String?> icon,
  Value<int> position,
});

class $$CachedNoteCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNoteCategoriesTable> {
  $$CachedNoteCategoriesTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$CachedNoteCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNoteCategoriesTable> {
  $$CachedNoteCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$CachedNoteCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNoteCategoriesTable> {
  $$CachedNoteCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedNoteCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedNoteCategoriesTable,
    CachedNoteCategory,
    $$CachedNoteCategoriesTableFilterComposer,
    $$CachedNoteCategoriesTableOrderingComposer,
    $$CachedNoteCategoriesTableAnnotationComposer,
    $$CachedNoteCategoriesTableCreateCompanionBuilder,
    $$CachedNoteCategoriesTableUpdateCompanionBuilder,
    (
      CachedNoteCategory,
      BaseReferences<_$AppDatabase, $CachedNoteCategoriesTable,
          CachedNoteCategory>
    ),
    CachedNoteCategory,
    PrefetchHooks Function()> {
  $$CachedNoteCategoriesTableTableManager(
      _$AppDatabase db, $CachedNoteCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNoteCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNoteCategoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedNoteCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              CachedNoteCategoriesCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            position: position,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              CachedNoteCategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            position: position,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedNoteCategoriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CachedNoteCategoriesTable,
        CachedNoteCategory,
        $$CachedNoteCategoriesTableFilterComposer,
        $$CachedNoteCategoriesTableOrderingComposer,
        $$CachedNoteCategoriesTableAnnotationComposer,
        $$CachedNoteCategoriesTableCreateCompanionBuilder,
        $$CachedNoteCategoriesTableUpdateCompanionBuilder,
        (
          CachedNoteCategory,
          BaseReferences<_$AppDatabase, $CachedNoteCategoriesTable,
              CachedNoteCategory>
        ),
        CachedNoteCategory,
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
  $$CachedRecipeCategoriesTableTableManager get cachedRecipeCategories =>
      $$CachedRecipeCategoriesTableTableManager(
          _db, _db.cachedRecipeCategories);
  $$CachedFamilyMembersTableTableManager get cachedFamilyMembers =>
      $$CachedFamilyMembersTableTableManager(_db, _db.cachedFamilyMembers);
  $$CachedShoppingItemsTableTableManager get cachedShoppingItems =>
      $$CachedShoppingItemsTableTableManager(_db, _db.cachedShoppingItems);
  $$CachedPantryItemsTableTableManager get cachedPantryItems =>
      $$CachedPantryItemsTableTableManager(_db, _db.cachedPantryItems);
  $$CachedNotesTableTableManager get cachedNotes =>
      $$CachedNotesTableTableManager(_db, _db.cachedNotes);
  $$CachedNoteCategoriesTableTableManager get cachedNoteCategories =>
      $$CachedNoteCategoriesTableTableManager(_db, _db.cachedNoteCategories);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(_db, _db.pendingChanges);
}
