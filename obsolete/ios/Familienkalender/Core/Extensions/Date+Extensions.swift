import Foundation

extension Date {
    private static let germanLocale = Locale(identifier: "de_DE")
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = germanLocale
        cal.firstWeekday = 2 // Monday
        return cal
    }()

    var mondayOfWeek: Date {
        let cal = Self.calendar
        let weekday = cal.component(.weekday, from: self)
        // .weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
        let daysFromMonday = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysFromMonday, to: self.startOfDay)!
    }

    var isoDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }

    var isoDateTimeString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    static func fromISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    static func fromISODate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    var germanDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Self.germanLocale
        return formatter.string(from: self)
    }

    var germanDayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MMMM"
        formatter.locale = Self.germanLocale
        return formatter.string(from: self)
    }

    var germanWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Self.germanLocale
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Self.germanLocale
        return formatter.string(from: self)
    }

    func adding(days: Int) -> Date {
        Self.calendar.date(byAdding: .day, value: days, to: self)!
    }

    var startOfDay: Date {
        Self.calendar.startOfDay(for: self)
    }
}
