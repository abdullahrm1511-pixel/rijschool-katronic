import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var settings = AppSettings()

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
                        VStack(alignment: .leading, spacing: 6) {
                            Text(student.name).bold()
                            Text("EUR \(store.outstandingAmount(for: student), specifier: "%.2f")")
                                .foregroundStyle(.red)
                            ForEach(store.data.lessons.filter { $0.studentId == student.id && !$0.paid && $0.kind == .lesson }) { lesson in
                                Text("\(formatDutchDate(lesson.date)) · \(lesson.startTime)-\(lesson.endTime)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear {
                settings = store.data.settings
            }
            .toolbar {
                Button("Bewaar") {
                    store.updateSettings(settings)
                }
            }
        }
    }
}
