import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var settings = AppSettings()
    @State private var lessonSearch = ""
    @State private var selectedLesson: Lesson?

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
                Section("Thema") {
                    Picker("Thema", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Lestijden") {
                    TextField("Starttijd", text: $settings.dayStartTime)
                    TextField("Eindtijd", text: $settings.dayEndTime)
                    Stepper("Lesduur: \(settings.lessonMinutes) minuten", value: $settings.lessonMinutes, in: 30...120, step: 5)
                    TextField("Standaard lesprijs", value: $settings.defaultLessonAmount, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Openstaand") {
                    Text("EUR \(store.outstandingAmount(), specifier: "%.2f")")
                        .font(.largeTitle.bold())
                    ForEach(store.data.students.filter { store.outstandingAmount(for: $0) > 0 }) { student in
                        let studentLessons = store.lessons(for: student).filter { $0.kind == .lesson }
                        let totalAmount = studentLessons.reduce(0) { $0 + $1.amount }
                        let paidAmount = studentLessons.reduce(0) { $0 + $1.paidAmount }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(student.name).bold()
                            Text("EUR \(store.outstandingAmount(for: student), specifier: "%.2f")")
                                .foregroundStyle(.red)
                            Text("Totaal EUR \(totalAmount, specifier: "%.2f") - betaald EUR \(paidAmount, specifier: "%.2f")")
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

                Section("Alle lessen zoeken") {
                    TextField("Zoek datum, leerling of tijd", text: $lessonSearch)
                }

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

                Section {
                    Button("Bewaar instellingen") {
                        store.updateSettings(settings)
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
        }
    }
}

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
