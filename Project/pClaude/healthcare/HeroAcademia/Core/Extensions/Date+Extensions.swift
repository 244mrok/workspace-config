import Foundation

extension Date {
    private static let japaneseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    var shortDateString: String {
        let formatter = Self.japaneseDateFormatter
        formatter.dateFormat = "M/d(E)"
        return formatter.string(from: self)
    }

    var mediumDateString: String {
        let formatter = Self.japaneseDateFormatter
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = Self.japaneseDateFormatter
        formatter.dateFormat = "H:mm"
        return formatter.string(from: self)
    }

    var dateTimeString: String {
        let formatter = Self.japaneseDateFormatter
        formatter.dateFormat = "M/d(E) H:mm"
        return formatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeString: String {
        if isToday { return "今日" }
        if isYesterday { return "昨日" }
        return shortDateString
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay, to: date.startOfDay).day ?? 0
    }
}
