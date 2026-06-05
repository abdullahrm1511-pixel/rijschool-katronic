import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet { save() }
    }

    private let storageKey = "rijschool-katronic-swift-data-v1"

    init() {
        if let saved = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: saved) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    func addStudent(_ student: Student) {
        data.students.insert(student, at: 0)
    }

    func updateStudent(_ student: Student) {
        data.students = data.students.map { $0.id == student.id ? student : $0 }
    }

    func deleteStudent(_ student: Student) {
        data.students.removeAll { $0.id == student.id }
        data.lessons.removeAll { $0.studentId == student.id }
    }

    func addLesson(_ lesson: Lesson) {
        data.lessons.append(lesson)
    }

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
        return created
    }

    func updateLesson(_ lesson: Lesson) {
        data.lessons = data.lessons.map { $0.id == lesson.id ? lesson : $0 }
    }

    func deleteLesson(_ lesson: Lesson) {
        data.lessons.removeAll { $0.id == lesson.id }
    }

    func lessons(on date: Date) -> [Lesson] {
        data.lessons
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func student(for lesson: Lesson) -> Student? {
        data.students.first { $0.id == lesson.studentId }
    }

    func outstandingAmount(for student: Student? = nil) -> Double {
        let lessons = data.lessons
            .filter { lesson in
                lesson.kind == .lesson && (student == nil || lesson.studentId == student?.id)
            }
        let total = lessons.reduce(0) { $0 + $1.amount }
        let paid = lessons.reduce(0) { $0 + $1.paidAmount }
        return max(0, total - paid)
    }

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

    func updateSettings(_ settings: AppSettings) {
        data.settings = settings
    }

    private func overlaps(_ a: Lesson, _ b: Lesson) -> Bool {
        Calendar.current.isDate(a.date, inSameDayAs: b.date) &&
        a.startTime < b.endTime &&
        a.endTime > b.startTime
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
