import Foundation

let dutchMonths = [
    "januari", "februari", "maart", "april", "mei", "juni",
    "juli", "augustus", "september", "oktober", "november", "december"
]

let dutchWeekdays = [
    "zondag", "maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag"
]

func formatDutchDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let weekday = dutchWeekdays[calendar.component(.weekday, from: date) - 1]
    let day = calendar.component(.day, from: date)
    let month = dutchMonths[calendar.component(.month, from: date) - 1]
    return "\(weekday) \(day) \(month)"
}

func parseTime(_ value: String) -> Int {
    let parts = value.split(separator: ":").map { Int($0) ?? 0 }
    return (parts.first ?? 0) * 60 + (parts.dropFirst().first ?? 0)
}

func makeTime(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    return String(format: "%02d:%02d", hours, mins)
}

func makeTimeSlots(start: String, end: String, minutes: Int) -> [(String, String)] {
    let startMinutes = parseTime(start)
    let endMinutes = parseTime(end)
    guard endMinutes > startMinutes else { return [] }

    var result: [(String, String)] = []
    var current = startMinutes
    while current + minutes <= endMinutes {
        result.append((makeTime(current), makeTime(current + minutes)))
        current += minutes
    }
    return result
}

func age(from birthDate: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.dateFormat = "dd-MM-yyyy"
    guard let date = formatter.date(from: birthDate) else { return "" }
    let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    return "\(years)"
}
