// Laadt Foundation voor datums, opslag, tekst en basisfuncties.
import Foundation

// Nederlandse maandnamen voor datums in de app.
let dutchMonths = [
    "januari", "februari", "maart", "april", "mei", "juni",
    "juli", "augustus", "september", "oktober", "november", "december"
]

// Nederlandse dagnamen voor agenda en overzichten.
let dutchWeekdays = [
    "zondag", "maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag"
]

// Maakt van een Date een leesbare Nederlandse datum.
// Functie die formatDutchDate uitvoert.
func formatDutchDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let weekday = dutchWeekdays[calendar.component(.weekday, from: date) - 1]
    let day = calendar.component(.day, from: date)
    let month = dutchMonths[calendar.component(.month, from: date) - 1]
    return "\(weekday) \(day) \(month)"
}

// Zet "08:20" om naar minuten vanaf middernacht.
// Functie die parseTime uitvoert.
func parseTime(_ value: String) -> Int {
    let parts = value.split(separator: ":").map { Int($0) ?? 0 }
    return (parts.first ?? 0) * 60 + (parts.dropFirst().first ?? 0)
}

// Zet minuten vanaf middernacht weer terug naar "HH:mm".
// Functie die makeTime uitvoert.
func makeTime(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    return String(format: "%02d:%02d", hours, mins)
}

// Maakt alle vrije agendablokken tussen start- en eindtijd.
// Functie die makeTimeSlots uitvoert.
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

// Combineert een datum met een losse tijdstring.
// Functie die dateWithTime uitvoert.
func dateWithTime(_ date: Date, time: String) -> Date {
    let minutes = parseTime(time)
    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    components.hour = minutes / 60
    components.minute = minutes % 60
    return Calendar.current.date(from: components) ?? date
}

// Haalt alleen de tijd uit een Date als "HH:mm".
// Functie die timeString uitvoert.
func timeString(from date: Date) -> String {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    return makeTime(((components.hour ?? 0) * 60) + (components.minute ?? 0))
}

// Berekent automatisch leeftijd uit de geboortedatum.
// Functie die age uitvoert.
func age(from birthDate: String) -> String {
    guard let date = parseBirthDate(birthDate) else { return "" }
    let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    return "\(years)"
}

// Leest geboortedatum in het formaat dd-MM-yyyy.
// Functie die parseBirthDate uitvoert.
func parseBirthDate(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.dateFormat = "dd-MM-yyyy"
    return formatter.date(from: value)
}

// Schrijft geboortedatum in het formaat dd-MM-yyyy.
// Functie die formatBirthDate uitvoert.
func formatBirthDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.dateFormat = "dd-MM-yyyy"
    return formatter.string(from: date)
}

// Kiest het beste navigatie-adres: ophaaladres als dat bestaat, anders woonadres.
func navigationAddress(for student: Student) -> String {
    let pickupAddress = student.pickupAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    if !pickupAddress.isEmpty {
        return pickupAddress
    }
    return student.address.trimmingCharacters(in: .whitespacesAndNewlines)
}

// Maakt een Apple Kaarten-link met de leerling als bestemming.
func appleMapsURL(for address: String) -> URL? {
    guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    return URL(string: "http://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d")
}

// Maakt een Google Maps-link met de leerling als bestemming.
func googleMapsURL(for address: String) -> URL? {
    guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    return URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(encodedAddress)&travelmode=driving")
}
