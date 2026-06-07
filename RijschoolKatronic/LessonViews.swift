import SwiftUI

// Scherm dat verschijnt als je een vrije plek in de agenda wilt plannen.
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
                // Keuze tussen losse les, vaste wekelijkse les of examen.
                Picker("Type", selection: $mode) {
                    Text("Les").tag(0)
                    Text("Wekelijks").tag(1)
                    Text("Examen").tag(2)
                }
                .pickerStyle(.segmented)

                // Alleen actieve leerlingen kunnen ingepland worden.
                Picker("Leerling", selection: $selectedStudentId) {
                    Text("Kies leerling").tag(UUID?.none)
                    ForEach(store.data.students.filter { $0.status == .actief }) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }

                if let selectedStudent {
                    // Laat direct zien wat deze leerling al betaald heeft en wat nog openstaat.
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
                            // Springt naar Instellingen waar het totale lesoverzicht staat.
                            dismiss()
                            onShowTotalOverview()
                        } label: {
                            Label("Totaaloverzicht", systemImage: "list.bullet.rectangle")
                        }
                    }
                }

                if mode != 2 {
                    // Voor lessen kies je alleen het aantal blokken; eindtijd wordt berekend.
                    Stepper("Aantal blokken: \(blockCount)", value: $blockCount, in: 1...6)
                } else {
                    // Examens gebruiken losse datum/tijd-kiezers.
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
                // Beginwaarden komen uit het gekozen agendablok.
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
                            // Vaste les: maak automatisch een reeks van wekelijkse lessen.
                            _ = store.addWeeklyLessons(
                                studentId: selectedStudentId,
                                startDate: plannedDate,
                                startTime: plannedStartTimeString,
                                endTime: actualEndTime,
                                amount: lessonAmount
                            )
                        } else {
                            // Losse les of examen: sla een enkele planning op.
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

    // Eindtijd voor lessen wordt berekend uit starttijd, lesduur en aantal blokken.
    private var actualEndTime: String {
        guard mode != 2 else { return plannedEndTimeString }
        return makeTime(parseTime(plannedStartTimeString) + (store.data.settings.lessonMinutes * blockCount))
    }

    // Bedrag van deze planning op basis van standaard lesprijs maal aantal blokken.
    private var lessonAmount: Double {
        store.data.settings.defaultLessonAmount * Double(blockCount)
    }

    // Starttijd uit de wheel picker als tekst.
    private var plannedStartTimeString: String {
        timeString(from: plannedStartTime)
    }

    // Eindtijd uit de wheel picker als tekst.
    private var plannedEndTimeString: String {
        timeString(from: plannedEndTime)
    }

    // De gekozen leerling uit de store.
    private var selectedStudent: Student? {
        guard let selectedStudentId else { return nil }
        return store.data.students.first { $0.id == selectedStudentId }
    }

    // Totaal betaald door deze leerling.
    private func paidTotal(for student: Student) -> Double {
        store.paidAmount(for: student)
    }

    // Tekst verandert naar Tegoed als leerling meer betaald heeft dan verschuldigd.
    private func balanceTitle(for student: Student) -> String {
        store.balanceAmount(for: student) < 0 ? "Tegoed" : "Openstaand bedrag"
    }

    // Bedragstekst voor openstaand of tegoed.
    private func balanceText(for student: Student) -> String {
        let balance = store.balanceAmount(for: student)
        if balance < 0 {
            return "+ EUR \(abs(balance), specifier: "%.2f")"
        }
        return "EUR \(balance, specifier: "%.2f")"
    }

    // Rood bij openstaand, groen bij betaald/tegoed.
    private func balanceColor(for student: Student) -> Color {
        let balance = store.balanceAmount(for: student)
        return balance < 0 ? .green : balance > 0 ? .red : .green
    }

    // Koppelt de juiste DatePicker aan datum, starttijd of eindtijd.
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

// Welke datum/tijd-picker in het plannen-scherm open staat.
private enum BookingDatePicker: Identifiable {
    case date
    case startTime
    case endTime

    var id: String {
        title
    }

    // Titel boven het wheel-scherm.
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

    // Bepaalt of de picker datum of tijd toont.
    var components: DatePickerComponents {
        switch self {
        case .date:
            return .date
        case .startTime, .endTime:
            return .hourAndMinute
        }
    }
}

// Herbruikbare rij voor datum/tijd met waarde rechts.
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

// iOS wheel picker in een klein sheet-scherm.
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

// Detailpagina van een les of examen.
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
                // Extra tab voor behandelde rijonderdelen per les.
                Picker("Tab", selection: $tab) {
                    Text("Les").tag(0)
                    Text("Onderdelen").tag(1)
                }
                .pickerStyle(.segmented)

                if tab == 0 {
                    // Basisgegevens van de les of het examen.
                    Section(lesson.kind == .exam ? "Examen" : "Les") {
                        if let student = store.student(for: lesson) {
                            Text(student.name)
                        }
                        Text("\(formatDutchDate(lesson.date)) - \(lesson.startTime)-\(lesson.endTime)")
                    }

                    if let student = store.student(for: lesson) {
                        // Contact- en locatiegegevens zodat de instructeur die bij de les ziet.
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
                        // Betaling per les, inclusief openstaand/tegoed voor de leerling.
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
                        // Verwijderen maakt het agendablok weer vrij.
                        store.deleteLesson(lesson)
                        dismiss()
                    } label: {
                        Text(lesson.kind == .exam ? "Examen verwijderen" : "Les verwijderen")
                    }
                } else {
                    // Per les aanvinken welke rijonderdelen behandeld zijn.
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
                // Ook opslaan als iemand terug swipet of het scherm sluit.
                saveLesson()
            }
            .onChange(of: lesson) { _ in
                // Direct opslaan tijdens wijzigen, zodat de Bewaar-knop niet kwetsbaar is.
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

    // Bepaalt automatisch of een les volledig betaald is.
    private var normalizedLesson: Lesson {
        var updated = lesson
        updated.paid = updated.kind == .exam || updated.paidAmount >= updated.amount
        return updated
    }

    // Schrijft de les naar de store en toont kort "Opgeslagen".
    private func saveLesson() {
        store.updateLesson(normalizedLesson)
        savedMessage = true
    }

    // Rekent openstaand/tegoed opnieuw met de nog niet opgeslagen invoer van deze les.
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

    // Label voor openstaand of tegoed op de lespagina.
    private func lessonBalanceTitle(for student: Student) -> String {
        balanceWithCurrentLesson(for: student) < 0 ? "Tegoed" : "Openstaand bedrag"
    }

    // Bedragstekst voor openstaand of tegoed op de lespagina.
    private func lessonBalanceText(for student: Student) -> String {
        let balance = balanceWithCurrentLesson(for: student)
        if balance < 0 {
            return "+ EUR \(abs(balance), specifier: "%.2f")"
        }
        return "EUR \(balance, specifier: "%.2f")"
    }

    // Rood/groen voor het saldo op de lespagina.
    private func lessonBalanceColor(for student: Student) -> Color {
        let balance = balanceWithCurrentLesson(for: student)
        return balance < 0 ? .green : balance > 0 ? .red : .green
    }
}

// Toont leerlinggegevens alleen als het veld gevuld is.
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

// Leest euro-invoer met komma of punt.
private func parseEuroInput(_ value: String) -> Double {
    Double(value.replacingOccurrences(of: ",", with: ".")) ?? 0
}

// Toont eurobedragen met komma, zoals in Nederland gebruikelijk is.
private func formatEuroInput(_ value: Double) -> String {
    String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
}
