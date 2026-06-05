import SwiftUI

struct BookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let date: Date
    let startTime: String
    let endTime: String
    let initialBlockCount: Int
    let initialMode: Int
    let onShowTotalOverview: () -> Void

    @State private var selectedStudentId: UUID?
    @State private var mode = 0
    @State private var blockCount = 1
    @State private var plannedDate = Date()
    @State private var plannedStartTime = Date()
    @State private var plannedEndTime = Date()
    @State private var activeDatePicker: BookingDatePicker?

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

                if let selectedStudent {
                    Section("Betaling leerling") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Betaald totaal")
                            Text("EUR \(paidTotal(for: selectedStudent), specifier: "%.2f")")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(balanceTitle(for: selectedStudent))
                            Text(balanceText(for: selectedStudent))
                                .font(.headline)
                                .foregroundStyle(balanceColor(for: selectedStudent))
                        }
                        if mode != 2 {
                            HStack {
                                Text("Deze planning")
                                Spacer()
                                Text("EUR \(lessonAmount, specifier: "%.2f")")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button {
                            dismiss()
                            onShowTotalOverview()
                        } label: {
                            Label("Totaaloverzicht", systemImage: "list.bullet.rectangle")
                        }
                    }
                }

                if mode != 2 {
                    Stepper("Aantal blokken: \(blockCount)", value: $blockCount, in: 1...6)
                } else {
                    Section("Datum en tijd") {
                        Button {
                            activeDatePicker = .date
                        } label: {
                            BookingPickerRow(title: "Datum", value: formatBirthDate(plannedDate))
                        }
                        Button {
                            activeDatePicker = .startTime
                        } label: {
                            BookingPickerRow(title: "Starttijd", value: plannedStartTimeString)
                        }
                        Button {
                            activeDatePicker = .endTime
                        } label: {
                            BookingPickerRow(title: "Eindtijd", value: plannedEndTimeString)
                        }
                    }
                }

                if mode == 1 {
                    Text("Maakt 24 wekelijkse lessen op dezelfde dag en tijd.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("\(plannedStartTimeString) - \(actualEndTime)")
            .onAppear {
                blockCount = max(1, initialBlockCount)
                mode = initialMode
                plannedDate = date
                plannedStartTime = dateWithTime(date, time: startTime)
                plannedEndTime = dateWithTime(date, time: endTime)
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
                                startDate: plannedDate,
                                startTime: plannedStartTimeString,
                                endTime: actualEndTime,
                                amount: lessonAmount
                            )
                        } else {
                            store.addLesson(Lesson(
                                studentId: selectedStudentId,
                                kind: mode == 2 ? .exam : .lesson,
                                date: plannedDate,
                                startTime: plannedStartTimeString,
                                endTime: mode == 2 ? plannedEndTimeString : actualEndTime,
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
            .sheet(item: $activeDatePicker) { picker in
                BookingDateWheelSheet(
                    title: picker.title,
                    date: dateBinding(for: picker),
                    components: picker.components
                )
            }
        }
    }

    private var actualEndTime: String {
        guard mode != 2 else { return plannedEndTimeString }
        return makeTime(parseTime(plannedStartTimeString) + (store.data.settings.lessonMinutes * blockCount))
    }

    private var lessonAmount: Double {
        store.data.settings.defaultLessonAmount * Double(blockCount)
    }

    private var plannedStartTimeString: String {
        timeString(from: plannedStartTime)
    }

    private var plannedEndTimeString: String {
        timeString(from: plannedEndTime)
    }

    private var selectedStudent: Student? {
        guard let selectedStudentId else { return nil }
        return store.data.students.first { $0.id == selectedStudentId }
    }

    private func paidTotal(for student: Student) -> Double {
        store.paidAmount(for: student)
    }

    private func balanceTitle(for student: Student) -> String {
        store.balanceAmount(for: student) < 0 ? "Tegoed" : "Openstaand bedrag"
    }

    private func balanceText(for student: Student) -> String {
        let balance = store.balanceAmount(for: student)
        if balance < 0 {
            return "+ EUR \(abs(balance), specifier: "%.2f")"
        }
        return "EUR \(balance, specifier: "%.2f")"
    }

    private func balanceColor(for student: Student) -> Color {
        let balance = store.balanceAmount(for: student)
        return balance < 0 ? .green : balance > 0 ? .red : .green
    }

    private func dateBinding(for picker: BookingDatePicker) -> Binding<Date> {
        switch picker {
        case .date:
            return $plannedDate
        case .startTime:
            return $plannedStartTime
        case .endTime:
            return $plannedEndTime
        }
    }
}

private enum BookingDatePicker: Identifiable {
    case date
    case startTime
    case endTime

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .date:
            return "Datum"
        case .startTime:
            return "Starttijd"
        case .endTime:
            return "Eindtijd"
        }
    }

    var components: DatePickerComponents {
        switch self {
        case .date:
            return .date
        case .startTime, .endTime:
            return .hourAndMinute
        }
    }
}

private struct BookingPickerRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct BookingDateWheelSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date
    let components: DatePickerComponents

    var body: some View {
        NavigationStack {
            DatePicker(title, selection: $date, displayedComponents: components)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .navigationTitle(title)
                .toolbar {
                    Button("Klaar") { dismiss() }
                }
        }
        .presentationDetents([.height(340)])
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

                    if let student = store.student(for: lesson) {
                        Section("Leerlinggegevens") {
                            LessonStudentInfoRow(title: "Adres", value: student.address)
                            LessonStudentInfoRow(title: "Ophaaladres", value: student.pickupAddress)
                            LessonStudentInfoRow(title: "Schoollocatie", value: student.schoolLocation)
                            LessonStudentInfoRow(title: "Werklocatie", value: student.workLocation)
                            LessonStudentInfoRow(title: "Telefoon", value: student.phone)
                            LessonStudentInfoRow(title: "E-mail", value: student.email)
                        }
                    }

                    Section("Notitie") {
                        TextField("Notitie", text: $lesson.note, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    if lesson.kind == .lesson {
                        Section("Betaling") {
                            TextField("Lesprijs in Euro", text: $amountText)
                                .keyboardType(.decimalPad)
                            TextField("Betaald bedrag", text: $paidAmountText)
                                .keyboardType(.decimalPad)
                            if let student = store.student(for: lesson) {
                                Text("\(lessonBalanceTitle(for: student)): \(lessonBalanceText(for: student))")
                                    .foregroundStyle(lessonBalanceColor(for: student))
                            } else {
                                Text("Openstaand bedrag: EUR \(max(0, lesson.remainingAmount), specifier: "%.2f")")
                                    .foregroundStyle(lesson.remainingAmount > 0 ? .red : .green)
                            }
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

    private func balanceWithCurrentLesson(for student: Student) -> Double {
        let lessons = store.lessons(for: student).filter { $0.kind == .lesson }
        let total = lessons.reduce(0) { result, existingLesson in
            result + (existingLesson.id == lesson.id ? lesson.amount : existingLesson.amount)
        }
        let paid = lessons.reduce(0) { result, existingLesson in
            result + (existingLesson.id == lesson.id ? lesson.paidAmount : existingLesson.paidAmount)
        }
        return total - paid
    }

    private func lessonBalanceTitle(for student: Student) -> String {
        balanceWithCurrentLesson(for: student) < 0 ? "Tegoed" : "Openstaand bedrag"
    }

    private func lessonBalanceText(for student: Student) -> String {
        let balance = balanceWithCurrentLesson(for: student)
        if balance < 0 {
            return "+ EUR \(abs(balance), specifier: "%.2f")"
        }
        return "EUR \(balance, specifier: "%.2f")"
    }

    private func lessonBalanceColor(for student: Student) -> Color {
        let balance = balanceWithCurrentLesson(for: student)
        return balance < 0 ? .green : balance > 0 ? .red : .green
    }
}

struct LessonStudentInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        }
    }
}

private func parseEuroInput(_ value: String) -> Double {
    Double(value.replacingOccurrences(of: ",", with: ".")) ?? 0
}

private func formatEuroInput(_ value: Double) -> String {
    String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
}
