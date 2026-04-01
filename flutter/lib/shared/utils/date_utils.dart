import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('dd.MM.yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final _dayNameFormat = DateFormat('EEEE', 'de_DE');
  static final _shortDayFormat = DateFormat('E', 'de_DE');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'de_DE');
  static final _isoDateFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatDayName(DateTime date) => _dayNameFormat.format(date);
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String toIsoDate(DateTime date) => _isoDateFormat.format(date);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  static DateTime endOfWeek(DateTime date) {
    return endOfDay(startOfWeek(date).add(const Duration(days: 6)));
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  static List<DateTime> weekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = startOfDay(date).difference(startOfDay(now)).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Morgen';
    if (diff == -1) return 'Gestern';
    if (diff > 1 && diff <= 6) return 'in $diff Tagen';
    if (diff < -1 && diff >= -6) return 'vor ${-diff} Tagen';
    return formatDate(date);
  }

  static int daysSince(DateTime date) {
    return startOfDay(DateTime.now()).difference(startOfDay(date)).inDays;
  }

  static DateTime nextWeekday(int weekday, {DateTime? from}) {
    final start = from ?? DateTime.now();
    var result = start;
    while (result.weekday != weekday) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }
}
