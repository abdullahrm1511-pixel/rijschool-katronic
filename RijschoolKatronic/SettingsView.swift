// Laadt SwiftUI voor schermen, knoppen, formulieren en navigatie.
import SwiftUI

// Instellingen-scherm met thema, lestijden, openstaand bedrag, lesoverzicht en export.
struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @FocusState private var focusedField: SettingsField?
    @State private var settings = AppSettings()
    @State private var lessonSearch = ""
    @State private var selectedLesson: Lesson?
    @State private var exportStartDate = Date()
    @State private var exportEndDate = Date()
    @State private var exportFileURL: URL?
    @State private var exportMessage = ""

    // Groepeert alle wekelijkse lessen tot vaste reeksen.
    private var fixedLessonSeries: [FixedLessonSeries] {
        let grouped = Dictionary(grouping: store.data.lessons.filter { $0.recurringSeriesId != nil }) { lesson in
            lesson.recurringSeriesId!
        }
        return grouped.compactMap { seriesId, lessons in
            guard let first = lessons.sorted(by: { $0.date < $1.date }).first else { return nil }
            let weekdayIndex = Calendar.current.component(.weekday, from: first.date)
            return FixedLessonSeries(
                id: seriesId,
                studentName: store.student(for: first)?.name ?? "Leerling",
                weekdayOrder: weekdayIndex == 1 ? 7 : weekdayIndex - 1,
                weekday: dutchWeekdays[weekdayIndex - 1],
                startTime: first.startTime,
                endTime: first.endTime,
                nextDate: lessons.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }.sorted { $0.date < $1.date }.first?.date,
                count: lessons.count
            )
        }
        .sorted {
            if $0.weekdayOrder == $1.weekdayOrder {
                return $0.startTime < $1.startTime
            }
            return $0.weekdayOrder < $1.weekdayOrder
        }
    }

    // Alle lessen, gefilterd op zoektekst zoals leerling, datum of notitie.
    private var filteredLessons: [Lesson] {
        store.data.lessons
            .sorted {
                if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.startTime < $1.startTime
                }
                return $0.date > $1.date
            }
            .filter { lesson in
                guard !lessonSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return true }
                let studentName = store.student(for: lesson)?.name ?? ""
                let haystack = [
                    studentName,
                    formatDutchDate(lesson.date),
                    lesson.startTime,
                    lesson.endTime,
                    lesson.note
                ].joined(separator: " ")
                return haystack.localizedCaseInsensitiveContains(lessonSearch)
            }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Thema verandert de uitstraling van de hele app.
                Section("Thema") {
                    Picker("Thema", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Werkdag, lesduur en standaard lesprijs voor nieuwe lessen.
                Section("Lestijden") {
                    TextField("Starttijd", text: $settings.dayStartTime)
                        .focused($focusedField, equals: .dayStart)
                    TextField("Eindtijd", text: $settings.dayEndTime)
                        .focused($focusedField, equals: .dayEnd)
                    Stepper("Lesduur: \(settings.lessonMinutes) minuten", value: $settings.lessonMinutes, in: 30...120, step: 5)
                    TextField("Standaard lesprijs", value: $settings.defaultLessonAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .lessonAmount)
                }

                // Totaal openstaand bedrag en per leerling de betaalregels.
                Section("Openstaand") {
                    Text("EUR \(store.outstandingAmount(), specifier: "%.2f")")
                        .font(.largeTitle.bold())
                    ForEach(store.data.students.filter { store.balanceAmount(for: $0) != 0 }) { student in
                        let studentLessons = store.lessons(for: student).filter { $0.kind == .lesson }
                        let totalAmount = studentLessons.reduce(0) { $0 + $1.amount }
                        let paidAmount = studentLessons.reduce(0) { $0 + $1.paidAmount }
                        let balance = store.balanceAmount(for: student)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(student.name).bold()
                            Text(balance < 0 ? "+ EUR \(abs(balance), specifier: "%.2f") tegoed" : "EUR \(balance, specifier: "%.2f") open")
                                .foregroundStyle(balance < 0 ? .green : .red)
                            Text("Totaal EUR \(totalAmount, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Betaald EUR \(paidAmount, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(studentLessons) { lesson in
                                Text("\(formatDutchDate(lesson.date)) - \(lesson.startTime)-\(lesson.endTime) - EUR \(lesson.amount, specifier: "%.2f") / betaald EUR \(lesson.paidAmount, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Overzicht van automatisch ingeplande wekelijkse lessen.
                Section("Vaste lessen") {
                    if fixedLessonSeries.isEmpty {
                        Text("Geen vaste lessen ingepland")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(fixedLessonSeries) { series in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(series.studentName).bold()
                                Text("\(series.weekday) - \(series.startTime)-\(series.endTime)")
                                    .foregroundStyle(.secondary)
                                Text("\(series.count) lessen ingepland")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let nextDate = series.nextDate {
                                    Text("Eerstvolgend: \(formatDutchDate(nextDate))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Button(role: .destructive) {
                                    store.deleteRecurringSeries(series.id)
                                } label: {
                                    Text("Verwijder vaste reeks")
                                }
                            }
                        }
                    }
                }

                // Zoekveld voor het complete lesarchief.
                Section("Alle lessen zoeken") {
                    TextField("Zoek datum, leerling of tijd", text: $lessonSearch)
                        .focused($focusedField, equals: .lessonSearch)
                }

                // Compleet lesoverzicht; tikken opent de lesdetails.
                Section("Alle lessen") {
                    if filteredLessons.isEmpty {
                        Text("Geen lessen gevonden")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredLessons) { lesson in
                            Button {
                                selectedLesson = lesson
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.student(for: lesson)?.name ?? "Leerling")
                                        .foregroundStyle(.primary)
                                    Text("\(formatDutchDate(lesson.date)) - \(lesson.startTime)-\(lesson.endTime)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if lesson.kind == .lesson {
                                        Text("EUR \(lesson.amount, specifier: "%.2f") - betaald EUR \(lesson.paidAmount, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Examen")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }

                // Maakt een CSV-bestand dat Excel kan openen en delen.
                Section("Excel export") {
                    DatePicker("Vanaf", selection: $exportStartDate, displayedComponents: .date)
                    DatePicker("Tot en met", selection: $exportEndDate, displayedComponents: .date)
                    Button("Maak export") {
                        exportFileURL = makeLessonExport()
                        exportMessage = exportFileURL == nil ? "Export maken is niet gelukt" : "Export staat klaar"
                    }
                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .foregroundStyle(exportFileURL == nil ? .red : .green)
                    }
                    if let exportFileURL {
                        ShareLink(item: exportFileURL) {
                            Label("Deel Excel export", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section {
                    Button("Bewaar instellingen") {
                        saveSettings()
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear {
                settings = store.data.settings
            }
            .onChange(of: settings) { updatedSettings in
                store.updateSettings(updatedSettings)
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        saveSettings()
                    }
                }
            }
        }
    }

    // Slaat instellingen op en sluit het toetsenbord.
    // Functie die saveSettings uitvoert.
    private func saveSettings() {
        store.updateSettings(settings)
        focusedField = nil
    }

    // Bouwt een CSV-export tussen twee gekozen datums.
    // Functie die makeLessonExport uitvoert.
    private func makeLessonExport() -> URL? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: min(exportStartDate, exportEndDate))
        let endDay = calendar.startOfDay(for: max(exportStartDate, exportEndDate))
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endDay) ?? endDay
        let lessons = store.data.lessons
            .filter { $0.date >= start && $0.date <= end }
            .sorted {
                if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.startTime < $1.startTime
                }
                return $0.date < $1.date
            }

        // Eerste rij zijn de kolomnamen in Excel.
        var rows = [
            ["Datum", "Start", "Einde", "Leerling", "Ophaaladres", "Schoollocatie", "Werklocatie", "Type", "Lesprijs", "Betaald", "Open", "Notitie", "Onderdelen"]
        ]
        for lesson in lessons {
            // Per les worden leerlinggegevens en behandelde onderdelen meegenomen.
            let student = store.student(for: lesson)
            let parts = instructionParts
                .filter { lesson.treatedPartIds.contains($0.id) }
                .map(\.title)
                .joined(separator: ", ")
            rows.append([
                formatDutchDate(lesson.date),
                lesson.startTime,
                lesson.endTime,
                student?.name ?? "Leerling",
                student?.pickupAddress ?? "",
                student?.schoolLocation ?? "",
                student?.workLocation ?? "",
                lesson.kind == .exam ? "Examen" : "Les",
                String(format: "%.2f", lesson.amount),
                String(format: "%.2f", lesson.paidAmount),
                String(format: "%.2f", max(0, lesson.remainingAmount)),
                lesson.note,
                parts
            ])
        }

        // Puntkomma werkt goed met Nederlandse Excel-instellingen.
        let csv = rows
            .map { $0.map(escapeCSV).joined(separator: ";") }
            .joined(separator: "\n")
        let fileName = "rijschool-katronic-export-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try ("\u{FEFF}" + csv).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // Zorgt dat puntkomma's en enters veilig in CSV blijven.
    // Functie die escapeCSV uitvoert.
    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(";") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}

// Velden die het toetsenbord kunnen openen in Instellingen.
private enum SettingsField: Hashable {
    case dayStart
    case dayEnd
    case lessonAmount
    case lessonSearch
}

// Samenvatting van een vaste wekelijkse lessenreeks.
private struct FixedLessonSeries: Identifiable {
    let id: UUID
    let studentName: String
    let weekdayOrder: Int
    let weekday: String
    let startTime: String
    let endTime: String
    let nextDate: Date?
    let count: Int
}
