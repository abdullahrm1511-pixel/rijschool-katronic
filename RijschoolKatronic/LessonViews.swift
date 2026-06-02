import SwiftUI

struct BookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let date: Date
    let startTime: String
    let endTime: String

    @State private var selectedStudentId: UUID?
    @State private var mode = 0

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $mode) {
                    Text("Les").tag(0)
                    Text("Wekelijks").tag(1)
                    Text("Examen").tag(2)
                }
                .pickerStyle(.segmented)

                Picker("Leerling", selection: $selectedStudentId) {
                    Text("Kies leerling").tag(UUID?.none)
                    ForEach(store.data.students.filter { $0.status == .actief }) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }
            }
            .navigationTitle("\(startTime) - \(endTime)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Plan") {
                        guard let selectedStudentId else { return }
                        if mode == 1 {
                            _ = store.addWeeklyLessons(
                                studentId: selectedStudentId,
                                startDate: date,
                                startTime: startTime,
                                endTime: endTime
                            )
                        } else {
                            store.addLesson(Lesson(
                                studentId: selectedStudentId,
                                kind: mode == 2 ? .exam : .lesson,
                                date: date,
                                startTime: startTime,
                                endTime: endTime,
                                note: "",
                                amount: mode == 2 ? 0 : store.data.settings.defaultLessonAmount,
                                paid: mode == 2
                            ))
                        }
                        dismiss()
                    }
                    .disabled(selectedStudentId == nil)
                }
            }
        }
    }
}

struct LessonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State var lesson: Lesson

    var body: some View {
        NavigationStack {
            Form {
                Section(lesson.kind == .exam ? "Examen" : "Les") {
                    if let student = store.student(for: lesson) {
                        Text(student.name)
                    }
                    Text("\(formatDutchDate(lesson.date)) · \(lesson.startTime)-\(lesson.endTime)")
                }

                Section("Notitie") {
                    TextField("Notitie", text: $lesson.note, axis: .vertical)
                }

                if lesson.kind == .lesson {
                    Section("Betaling") {
                        TextField("Bedrag", value: $lesson.amount, format: .number)
                            .keyboardType(.decimalPad)
                        Toggle("Betaald", isOn: $lesson.paid)
                    }
                }

                Button(role: .destructive) {
                    store.deleteLesson(lesson)
                    dismiss()
                } label: {
                    Text(lesson.kind == .exam ? "Examen verwijderen" : "Les verwijderen")
                }
            }
            .navigationTitle(lesson.kind == .exam ? "Examen" : "Les")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        store.updateLesson(lesson)
                        dismiss()
                    }
                }
            }
        }
    }
}
