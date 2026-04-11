import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/notification_level.dart';
import '../domain/notification_preference.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref);
});

class NotificationRepository {
  final Ref _ref;
  NotificationRepository(this._ref);

  Future<List<NotificationLevel>> listLevels() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get(Endpoints.notificationsLevels);
    final list = (res.data as List).cast<dynamic>();
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationLevel.fromJson)
        .toList();
  }

  Future<NotificationLevel> createLevel(NotificationLevel level) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post(Endpoints.notificationsLevels, data: level.toCreateJson());
    return NotificationLevel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<NotificationLevel> updateLevel({
    required int id,
    String? name,
    int? position,
    List<int>? remindersMinutes,
    bool? isDefault,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.put(
      Endpoints.notificationsLevel(id),
      data: {
        if (name != null) 'name': name,
        if (position != null) 'position': position,
        if (remindersMinutes != null) 'reminders_minutes': remindersMinutes,
        if (isDefault != null) 'is_default': isDefault,
      },
    );
    return NotificationLevel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteLevel(int id) async {
    final dio = _ref.read(dioProvider);
    await dio.delete(Endpoints.notificationsLevel(id));
  }

  Future<void> reorderLevels(List<NotificationLevel> levels) async {
    final dio = _ref.read(dioProvider);
    await dio.put(
      Endpoints.notificationsLevelsReorder,
      data: {
        'items': [
          for (var i = 0; i < levels.length; i++) {'id': levels[i].id, 'position': i}
        ],
      },
    );
  }

  Future<List<NotificationPreference>> getPreferences() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get(Endpoints.notificationsPreferences);
    final items = ((res.data as Map<String, dynamic>)['items'] as List).cast<dynamic>();
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationPreference.fromJson)
        .toList();
  }

  Future<List<NotificationPreference>> updatePreferences(List<NotificationPreference> items) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.put(
      Endpoints.notificationsPreferences,
      data: {
        'items': items.map((e) => e.toJson()).toList(),
      },
    );
    final out = ((res.data as Map<String, dynamic>)['items'] as List).cast<dynamic>();
    return out
        .whereType<Map<String, dynamic>>()
        .map(NotificationPreference.fromJson)
        .toList();
  }
}

