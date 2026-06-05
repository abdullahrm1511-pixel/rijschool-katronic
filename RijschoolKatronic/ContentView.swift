import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }

            StudentsView()
                .tabItem { Label("Leerlingen", systemImage: "person.2") }

            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
        }
        .tint(accentColor)
        .preferredColorScheme(colorScheme)
    }

    private var accentColor: Color {
        switch store.data.settings.theme {
        case .donker:
            return .blue
        case .blauw:
            return .cyan
        case .licht:
            return .orange
        }
    }

    private var colorScheme: ColorScheme? {
        switch store.data.settings.theme {
        case .donker:
            return .dark
        case .licht:
            return .light
        case .blauw:
            return nil
        }
    }
}

struct AgendaView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDate = Date()
    @State private var bookingSlot: (String, String)?
    @State private var bookingDoubleBlock = false
    @State private var selectedLesson: Lesson?
    @State private var showExamOverview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weekStrip

                    Text(formatDutchDate(selectedDate))
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    examBanner

                    ForEach(timeSlots, id: \.0) { slot in
                        let dayLessons = store.lessons(on: selectedDate)
                        let lesson = dayLessons.first { $0.startTime == slot.0 }
                        let covered = lesson == nil && dayLessons.contains {
                            parseTime($0.startTime) < parseTime(slot.0) && parseTime($0.endTime) > parseTime(slot.0)
                        }
                        if !covered {
                            AgendaRow(
                                startTime: slot.0,
                                endTime: lesson?.endTime ?? slot.1,
                                lesson: lesson,
                                student: lesson.flatMap { store.student(for: $0) },
                                span: lesson.map(slotSpan(for:)) ?? 1
                            )
                            .onTapGesture {
                                if let lesson {
                                    selectedLesson = lesson
                                } else {
                                    bookingDoubleBlock = false
                                    bookingSlot = slot
                                }
                            }
                            .onLongPressGesture {
                                if lesson == nil {
                                    bookingDoubleBlock = true
                                    bookingSlot = slot
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Opties") {
                        Button("Alle examens") {
                            showExamOverview = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Vandaag") { selectedDate = Date() }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -70 {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                        if value.translation.width > 70 {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    }
            )
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .sheet(isPresented: $showExamOverview) {
                ExamOverviewView()
            }
            .sheet(isPresented: Binding(
                get: { bookingSlot != nil },
                set: { if !$0 { bookingSlot = nil } }
            )) {
                if let bookingSlot {
                    BookingSheet(
                        date: selectedDate,
                        startTime: bookingSlot.0,
                        endTime: bookingSlot.1,
                        initialDoubleBlock: bookingDoubleBlock
                    )
                }
            }
        }
    }

    private var timeSlots: [(String, String)] {
        makeTimeSlots(
            start: store.data.settings.dayStartTime,
            end: store.data.settings.dayEndTime,
            minutes: store.data.settings.lessonMinutes
        )
    }

    private func slotSpan(for lesson: Lesson) -> Int {
        let duration = parseTime(lesson.endTime) - parseTime(lesson.startTime)
        guard duration > store.data.settings.lessonMinutes else { return 1 }
        return max(1, Int(ceil(Double(duration) / Double(store.data.settings.lessonMinutes))))
    }

    private var weekStrip: some View {
        let days = (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset - weekdayOffset, to: selectedDate)
        }
        return HStack {
            ForEach(days, id: \.self) { day in
                Button {
                    selectedDate = day
                } label: {
                    VStack {
                        Text(dayLetter(day))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                            .background(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.red : Color.clear)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        }
    }

    private var weekdayOffset: Int {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        return weekday == 1 ? 6 : weekday - 2
    }

    private func dayLetter(_ date: Date) -> String {
        let letters = ["Z", "M", "D", "W", "D", "V", "Z"]
        return letters[Calendar.current.component(.weekday, from: date) - 1]
    }

    @ViewBuilder
    private var examBanner: some View {
        let exams = store.lessons(on: selectedDate).filter { $0.kind == .exam }
        if !exams.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Examen vandaag")
                    .font(.headline)
                    .foregroundStyle(.orange)
                ForEach(exams) { exam in
                    Text("\(exam.startTime) - \(store.student(for: exam)?.name ?? "Leerling")")
                        .font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.orange.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ExamOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var selectedLesson: Lesson?

    private var exams: [Lesson] {
        store.data.lessons
            .filter { $0.kind == .exam }
            .sorted {
                if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.startTime < $1.startTime
                }
                return $0.date < $1.date
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if exams.isEmpty {
                    Text("Geen examens ingepland")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exams) { exam in
                        Button {
                            selectedLesson = exam
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(store.student(for: exam)?.name ?? "Leerling")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(formatDutchDate(exam.date)) - \(exam.startTime)-\(exam.endTime)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Alle examens")
            .toolbar {
                Button("Sluit") { dismiss() }
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
        }
    }
}

struct AgendaRow: View {
    let startTime: String
    let endTime: String
    let lesson: Lesson?
    let student: Student?
    let span: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing) {
                Text(startTime).bold()
                Text(endTime).font(.caption).foregroundStyle(.secondary)
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 8) {
                if let lesson, let student {
                    HStack {
                        Text(student.name).font(.headline)
                        Spacer()
                        Text(lesson.kind == .exam ? "Examen" : lesson.remainingAmount <= 0 ? "Betaald" : "Open")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(lesson.kind == .exam ? Color.orange : lesson.remainingAmount <= 0 ? Color.green : Color.red)
                            .clipShape(Capsule())
                    }
                    Text(lesson.kind == .exam ? "Examen ingepland" : student.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if lesson.kind == .lesson {
                        Text("EUR \(lesson.amount, specifier: "%.2f") - betaald EUR \(lesson.paidAmount, specifier: "%.2f")")
                            .font(.caption.bold())
                    }
                } else {
                    Text("Vrije plek").font(.headline)
                    Text("Tik om te plannen").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: CGFloat(72 * span))
            .background(lesson?.kind == .exam ? Color.orange.opacity(0.16) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
