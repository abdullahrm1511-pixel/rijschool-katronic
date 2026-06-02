import Foundation

enum StudentStatus: String, Codable, CaseIterable, Identifiable {
    case actief = "Actief"
    case geslaagd = "Geslaagd"

    var id: String { rawValue }
}

enum HealthStatus: String, Codable, CaseIterable, Identifiable {
    case nietGestart = "Niet gestart"
    case aangevraagd = "Aangevraagd"
    case goedgekeurd = "Goedgekeurd"
    case extraBeoordeling = "Extra beoordeling"

    var id: String { rawValue }
}

enum TheoryStatus: String, Codable, CaseIterable, Identifiable {
    case nietGestart = "Niet gestart"
    case bezig = "Bezig"
    case gehaald = "Gehaald"
    case verlopen = "Verlopen"

    var id: String { rawValue }
}

enum LessonKind: String, Codable {
    case lesson
    case exam
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case donker = "Donker"
    case blauw = "Blauw"

    var id: String { rawValue }
}

struct Student: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var address: String
    var birthDate: String
    var phone: String
    var email: String
    var status: StudentStatus
    var healthStatus: HealthStatus
    var theoryStatus: TheoryStatus
    var pickupAddress: String
    var notes: String
    var createdAt = Date()
}

struct Lesson: Identifiable, Codable, Equatable {
    var id = UUID()
    var studentId: UUID
    var kind: LessonKind
    var date: Date
    var startTime: String
    var endTime: String
    var note: String
    var amount: Double
    var paid: Bool
    var recurringSeriesId: UUID?
    var createdAt = Date()
}

struct AppSettings: Codable, Equatable {
    var theme: AppTheme = .donker
    var dayStartTime = "08:20"
    var dayEndTime = "18:00"
    var lessonMinutes = 50
    var defaultLessonAmount = 55.0
}

struct AppData: Codable {
    var students: [Student] = []
    var lessons: [Lesson] = []
    var settings = AppSettings()
}
