import SwiftUI

struct BookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let date: Date
    let startTime: String
    let endTime: String
    let initialDoubleBlock: Bool

    @State private var selectedStudentId: UUID?
    @State private var mode = 0
    @State private var doubleBlock = false

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

                if mode != 2 {
                    Toggle("Dubbel blok", isOn: $doubleBlock)
                }

                if mode == 1 {
                    Text("Maakt 24 wekelijkse lessen op dezelfde dag en tijd.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("\(startTime) - \(actualEndTime)")
            .onAppear {
                doubleBlock = initialDoubleBlock
            }
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
                                endTime: actualEndTime,
                                amount: lessonAmount
                            )
                        } else {
                            store.addLesson(Lesson(
                                studentId: selectedStudentId,
                                kind: mode == 2 ? .exam : .lesson,
                                date: date,
                                startTime: startTime,
                                endTime: mode == 2 ? endTime : actualEndTime,
                                note: "",
                                amount: mode == 2 ? 0 : lessonAmount,
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

    private var actualEndTime: String {
        guard doubleBlock, mode != 2 else { return endTime }
        return makeTime(parseTime(startTime) + (store.data.settings.lessonMinutes * 2))
    }

    private var lessonAmount: Double {
        doubleBlock ? store.data.settings.defaultLessonAmount * 2 : store.data.settings.defaultLessonAmount
    }
}

struct LessonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State var lesson: Lesson
    @State private var tab = 0
    @State private var savedMessage = false
    @State private var amountText = ""
    @State private var paidAmountText = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Tab", selection: $tab) {
                    Text("Les").tag(0)
                    Text("Onderdelen").tag(1)
                }
                .pickerStyle(.segmented)

                if tab == 0 {
                    Section(lesson.kind == .exam ? "Examen" : "Les") {
                        if let student = store.student(for: lesson) {
                            Text(student.name)
                        }
                        Text("\(formatDutchDate(lesson.date)) - \(lesson.startTime)-\(lesson.endTime)")
                    }

                    Section("Notitie") {
                        TextField("Notitie", text: $lesson.note, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    if lesson.kind == .lesson {
                        Section("Betaling") {
                            TextField("Lesprijs", text: $amountText)
                                .keyboardType(.decimalPad)
                            TextField("Betaald bedrag", text: $paidAmountText)
                                .keyboardType(.decimalPad)
                            Text("Open voor deze les: EUR \(max(0, lesson.remainingAmount), specifier: "%.2f")")
                                .foregroundStyle(lesson.remainingAmount > 0 ? .red : .green)
                            Button("Zet op volledig betaald") {
                                lesson.paidAmount = lesson.amount
                                lesson.paid = true
                            }
                        }
                    }

                    if savedMessage {
                        Section {
                            Text("Opgeslagen")
                                .foregroundStyle(.green)
                        }
                    }

                    Button(role: .destructive) {
                        store.deleteLesson(lesson)
                        dismiss()
                    } label: {
                        Text(lesson.kind == .exam ? "Examen verwijderen" : "Les verwijderen")
                    }
                } else {
                    Section("Behandelde onderdelen") {
                        ForEach(instructionParts) { part in
                            Toggle(part.title, isOn: Binding(
                                get: { lesson.treatedPartIds.contains(part.id) },
                                set: { isOn in
                                    if isOn {
                                        if !lesson.treatedPartIds.contains(part.id) {
                                            lesson.treatedPartIds.append(part.id)
                                        }
                                    } else {
                                        lesson.treatedPartIds.removeAll { $0 == part.id }
                                    }
                                    lesson.treatedPartIds.sort()
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle(lesson.kind == .exam ? "Examen" : "Les")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        saveLesson()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        saveLesson()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                saveLesson()
            }
            .onChange(of: lesson) { _ in
                store.updateLesson(normalizedLesson)
            }
            .onAppear {
                amountText = formatEuroInput(lesson.amount)
                paidAmountText = formatEuroInput(lesson.paidAmount)
            }
            .onChange(of: amountText) { value in
                lesson.amount = parseEuroInput(value)
            }
            .onChange(of: paidAmountText) { value in
                lesson.paidAmount = parseEuroInput(value)
            }
        }
    }

    private var normalizedLesson: Lesson {
        var updated = lesson
        updated.paid = updated.kind == .exam || updated.paidAmount >= updated.amount
        return updated
    }

    private func saveLesson() {
        store.updateLesson(normalizedLesson)
        savedMessage = true
    }
}

private func parseEuroInput(_ value: String) -> Double {
    Double(value.replacingOccurrences(of: ",", with: ".")) ?? 0
}

private func formatEuroInput(_ value: Double) -> String {
    String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
}
