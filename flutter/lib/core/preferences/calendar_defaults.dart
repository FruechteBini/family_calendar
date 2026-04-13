import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';

class CalendarDefaultsPreferences {
  final int? personalCalendarCategoryId;
  final int? familyDefaultCalendarCategoryId;

  const CalendarDefaultsPreferences({
    this.personalCalendarCategoryId,
    this.familyDefaultCalendarCategoryId,
  });
}

const _kPersonalCalCat = 'calendar_personal_category_id';
const _kFamilyCalCat = 'calendar_family_default_category_id';

class CalendarDefaultsNotifier extends AsyncNotifier<CalendarDefaultsPreferences> {
  @override
  Future<CalendarDefaultsPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final dio = ref.read(dioProvider);
      final prefResp = await dio.get(Endpoints.authPreferences);
      final prefData = prefResp.data as Map<String, dynamic>;
      final personal = prefData['personal_calendar_category_id'] as int?;
      if (personal != null) {
        await prefs.setInt(_kPersonalCalCat, personal);
      } else {
        await prefs.remove(_kPersonalCalCat);
      }

      int? familyDefault;
      try {
        final famResp = await dio.get(Endpoints.authFamily);
        final famData = famResp.data as Map<String, dynamic>;
        familyDefault =
            famData['default_family_calendar_category_id'] as int?;
      } catch (_) {
        familyDefault = null;
      }
      if (familyDefault != null) {
        await prefs.setInt(_kFamilyCalCat, familyDefault);
      } else {
        await prefs.remove(_kFamilyCalCat);
      }

      return CalendarDefaultsPreferences(
        personalCalendarCategoryId: personal,
        familyDefaultCalendarCategoryId: familyDefault,
      );
    } catch (_) {
      final p = prefs.getInt(_kPersonalCalCat);
      final f = prefs.getInt(_kFamilyCalCat);
      return CalendarDefaultsPreferences(
        personalCalendarCategoryId: p,
        familyDefaultCalendarCategoryId: f,
      );
    }
  }

  Future<void> setPersonalCalendarCategoryId(int? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setInt(_kPersonalCalCat, categoryId);
    } else {
      await prefs.remove(_kPersonalCalCat);
    }
    final fam = state.valueOrNull?.familyDefaultCalendarCategoryId;
    state = AsyncData(CalendarDefaultsPreferences(
      personalCalendarCategoryId: categoryId,
      familyDefaultCalendarCategoryId: fam,
    ));
    try {
      await ref.read(dioProvider).patch(
            Endpoints.authPreferences,
            data: {'personal_calendar_category_id': categoryId},
          );
    } catch (_) {
      // local value kept; retry on next load
    }
  }

  Future<void> setFamilyDefaultCalendarCategoryId(int? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setInt(_kFamilyCalCat, categoryId);
    } else {
      await prefs.remove(_kFamilyCalCat);
    }
    final personal = state.valueOrNull?.personalCalendarCategoryId;
    state = AsyncData(CalendarDefaultsPreferences(
      personalCalendarCategoryId: personal,
      familyDefaultCalendarCategoryId: categoryId,
    ));
    try {
      await ref.read(dioProvider).patch(
            Endpoints.authFamily,
            data: {'default_family_calendar_category_id': categoryId},
          );
    } catch (_) {
      // local value kept
    }
  }

  void refreshFromServer() {
    ref.invalidateSelf();
  }
}

final calendarDefaultsProvider =
    AsyncNotifierProvider<CalendarDefaultsNotifier, CalendarDefaultsPreferences>(
  CalendarDefaultsNotifier.new,
);
