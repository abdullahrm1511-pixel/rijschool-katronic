import Foundation

// Centrale app-store: bewaart data, wijzigt data en schrijft alles lokaal naar de iPhone.
@MainActor
final class AppStore: ObservableObject {
    // Zodra data verandert, wordt deze automatisch opgeslagen.
    @Published var data: AppData {
        didSet { save() }
    }

    private let storageKey = "rijschool-katronic-swift-data-v1"

    // Laadt opgeslagen data bij het openen van de app.
    init() {
        if let saved = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: saved) {
            var migrated = decoded
            migrated.students = migrated.students.map(normalizedStudent)
            data = migrated
        } else {
            data = AppData()
        }
    }

    // Voegt een nieuwe leerling toe.
    func addStudent(_ student: Student) {
        data.students.insert(normalizedStudent(student), at: 0)
        save()
    }

    // Past bestaande leerlinggegevens aan.
    func updateStudent(_ student: Student) {
        let updated = normalizedStudent(student)
        data.students = data.students.map { $0.id == updated.id ? updated : $0 }
        save()
    }

    // Verwijdert een leerling inclusief alle lessen van die leerling.
    func deleteStudent(_ student: Student) {
        data.students.removeAll { $0.id == student.id }
        data.lessons.removeAll { $0.studentId == student.id }
        save()
    }

    // Zet een losse les of examen in de agenda.
    func addLesson(_ lesson: Lesson) {
        data.lessons.append(lesson)
        save()
    }

    // Maakt 24 wekelijkse lessen en slaat drukke tijden over.
    func addWeeklyLessons(studentId: UUID, startDate: Date, startTime: String, endTime: String, amount: Double) -> Int {
        let seriesId = UUID()
        var created = 0
        for week in 0..<24 {
            guard let date = Calendar.current.date(byAdding: .day, value: week * 7, to: startDate) else {
                continue
            }
            let candidate = Lesson(
                studentId: studentId,
                kind: .lesson,
                date: date,
                startTime: startTime,
                endTime: endTime,
                note: "",
                amount: amount,
                paid: false,
                recurringSeriesId: seriesId
            )
            if data.lessons.contains(where: { overlaps($0, candidate) }) {
                continue
            }
            data.lessons.append(candidate)
            created += 1
        }
        save()
        return created
    }

    // Slaat wijzigingen op een bestaande les op.
    func updateLesson(_ lesson: Lesson) {
        guard let index = data.lessons.firstIndex(where: { $0.id == lesson.id }) else { return }
        data.lessons[index] = lesson
        save()
    }

    // Verwijdert een les zodat het blok weer vrij wordt.
    func deleteLesson(_ lesson: Lesson) {
        data.lessons.removeAll { $0.id == lesson.id }
        save()
    }

    // Verwijdert een complete vaste lessenreeks.
    func deleteRecurringSeries(_ seriesId: UUID) {
        data.lessons.removeAll { $0.recurringSeriesId == seriesId }
        save()
    }

    // Geeft alle lessen van een bepaalde dag terug, gesorteerd op tijd.
    func lessons(on date: Date) -> [Lesson] {
        data.lessons
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    // Zoekt de leerling die bij een les hoort.
    func student(for lesson: Lesson) -> Student? {
        data.students.first { $0.id == lesson.studentId }
    }

    // Alleen het openstaande bedrag; tegoed wordt hier als 0 getoond.
    func outstandingAmount(for student: Student? = nil) -> Double {
        max(0, balanceAmount(for: student))
    }

    // Rekent totale schuld of tegoed uit. Negatief betekent tegoed.
    func balanceAmount(for student: Student? = nil) -> Double {
        let lessons = data.lessons
            .filter { lesson in
                lesson.kind == .lesson && (student == nil || lesson.studentId == student?.id)
            }
        let total = lessons.reduce(0) { $0 + $1.amount }
        let paid = lessons.reduce(0) { $0 + $1.paidAmount }
        return total - paid
    }

    // Telt op hoeveel er betaald is.
    func paidAmount(for student: Student? = nil) -> Double {
        data.lessons
            .filter { lesson in
                lesson.kind == .lesson && (student == nil || lesson.studentId == student?.id)
            }
            .reduce(0) { $0 + $1.paidAmount }
    }

    // Alle lessen van een leerling, nieuwste bovenaan.
    func lessons(for student: Student) -> [Lesson] {
        data.lessons
            .filter { $0.studentId == student.id }
            .sorted {
                if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.startTime < $1.startTime
                }
                return $0.date > $1.date
            }
    }

    // Telt per leerling hoe vaak ieder rijonderdeel behandeld is.
    func treatedPartCounts(for student: Student) -> [TreatedPartCount] {
        let counts = lessons(for: student)
            .flatMap(\.treatedPartIds)
            .reduce(into: [Int: Int]()) { result, partId in
                result[partId, default: 0] += 1
            }
        return instructionParts.compactMap { part in
            guard let count = counts[part.id], count > 0 else { return nil }
            return TreatedPartCount(part: part, count: count)
        }
    }

    // Slaat instellingen zoals thema, lestijden en lesprijs op.
    func updateSettings(_ settings: AppSettings) {
        data.settings = settings
        save()
    }

    // Controleert of twee lessen elkaar in tijd raken.
    private func overlaps(_ a: Lesson, _ b: Lesson) -> Bool {
        Calendar.current.isDate(a.date, inSameDayAs: b.date) &&
        a.startTime < b.endTime &&
        a.endTime > b.startTime
    }

    // Houdt oude data netjes bij en laat theorie verlopen na twee jaar.
    private func normalizedStudent(_ student: Student) -> Student {
        var updated = student
        if updated.theoryStatus == .gehaald && updated.theoryPassedDate == nil {
            updated.theoryPassedDate = Date()
        }
        if let passedDate = updated.theoryPassedDate,
           let expiryDate = Calendar.current.date(byAdding: .year, value: 2, to: passedDate),
           expiryDate <= Date() {
            updated.theoryStatus = .verlopen
        }
        return updated
    }

    // Schrijft alle appdata naar UserDefaults, lokaal op de iPhone.
    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            UserDefaults.standard.synchronize()
        }
    }
}
