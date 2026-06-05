import SwiftUI

enum AppTab: Hashable {
    case agenda
    case students
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab: AppTab = .agenda

    var body: some View {
        TabView(selection: $selectedTab) {
            AgendaView(selectedTab: $selectedTab)
                .tabItem { Label("Agenda", systemImage: "calendar") }
                .tag(AppTab.agenda)

            StudentsView()
                .tabItem { Label("Leerlingen", systemImage: "person.2") }
                .tag(AppTab.students)

            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
                .tag(AppTab.settings)
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
    @Binding var selectedTab: AppTab
    @State private var selectedDate = Date()
    @State private var bookingSlot: (String, String)?
    @State private var bookingBlockCount = 1
    @State private var bookingMode = 0
    @State private var pendingBookingSlot: (String, String)?
    @State private var pendingBlockCount = 1
    @State private var showOverlapWarning = false
    @State private var selectedLesson: Lesson?
    @State private var showExamOverview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weekStrip

                    dayNavigator

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
                                    startBooking(slot, blockCount: 1)
                                }
                            }
                            .gesture(
                                LongPressGesture(minimumDuration: 0.45)
                                    .sequenced(before: DragGesture(minimumDistance: 0))
                                    .onEnded { value in
                                        guard lesson == nil else { return }
                                        if case .second(true, let drag?) = value {
                                            startBooking(slot, blockCount: blockCount(for: drag.translation.height, from: slot))
                                        } else {
                                            startBooking(slot, blockCount: 2)
                                        }
                                    }
                            )
                            .overlay(alignment: .bottomTrailing) {
                                if lesson == nil {
                                    Text("Houd vast + sleep")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 10)
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
                        Button("Examen inplannen") {
                            openBooking(defaultBookingSlot, blockCount: 1, mode: 2)
                        }
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
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if value.translation.width < -70 {
                                changeWeek(by: 1)
                            }
                            if value.translation.width > 70 {
                                changeWeek(by: -1)
                            }
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
                        initialBlockCount: bookingBlockCount,
                        initialMode: bookingMode,
                        onShowTotalOverview: {
                            selectedTab = .settings
                        }
                    )
                }
            }
            .alert("Deze blokken raken een bestaande les", isPresented: $showOverlapWarning) {
                Button("Annuleer", role: .cancel) { }
                Button("Toch openen") {
                    if let pendingBookingSlot {
                        openBooking(pendingBookingSlot, blockCount: pendingBlockCount, mode: 0)
                    }
                }
            } message: {
                Text("Je selectie loopt over een tijd waar al een les of examen staat. Controleer even of dit geen ongelukje is.")
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

    private var defaultBookingSlot: (String, String) {
        (
            store.data.settings.dayStartTime,
            makeTime(parseTime(store.data.settings.dayStartTime) + store.data.settings.lessonMinutes)
        )
    }

    private func slotSpan(for lesson: Lesson) -> Int {
        let duration = parseTime(lesson.endTime) - parseTime(lesson.startTime)
        guard duration > store.data.settings.lessonMinutes else { return 1 }
        return max(1, Int(ceil(Double(duration) / Double(store.data.settings.lessonMinutes))))
    }

    private func blockCount(for dragHeight: CGFloat, from slot: (String, String)) -> Int {
        let rowHeight: CGFloat = 88
        let draggedBlocks = Int(max(0, dragHeight) / rowHeight) + 1
        return min(max(1, draggedBlocks), maxBlocks(from: slot))
    }

    private func maxBlocks(from slot: (String, String)) -> Int {
        guard let index = timeSlots.firstIndex(where: { $0.0 == slot.0 }) else { return 1 }
        return max(1, timeSlots.count - index)
    }

    private func startBooking(_ slot: (String, String), blockCount: Int) {
        let count = min(max(1, blockCount), maxBlocks(from: slot))
        if count > 1 && overlapsExistingLesson(startTime: slot.0, blockCount: count) {
            pendingBookingSlot = slot
            pendingBlockCount = count
            showOverlapWarning = true
        } else {
            openBooking(slot, blockCount: count, mode: 0)
        }
    }

    private func openBooking(_ slot: (String, String), blockCount: Int, mode: Int) {
        bookingBlockCount = blockCount
        bookingMode = mode
        bookingSlot = slot
    }

    private func overlapsExistingLesson(startTime: String, blockCount: Int) -> Bool {
        let start = parseTime(startTime)
        let end = start + (store.data.settings.lessonMinutes * blockCount)
        return store.lessons(on: selectedDate).contains { lesson in
            parseTime(lesson.startTime) < end && parseTime(lesson.endTime) > start
        }
    }

    private var dayNavigator: some View {
        HStack(spacing: 12) {
            Button {
                changeWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Text(formatDutchDate(selectedDate))
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)

            Button {
                changeWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
    }

    private func changeWeek(by weeks: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: weeks * 7, to: selectedDate) ?? selectedDate
        }
    }

    private var weekStrip: some View {
        let days = (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset - weekdayOffset, to: selectedDate)
        }
        return HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = day
                    }
                } label: {
                    VStack(spacing: 3) {
                        Text(dayLetter(day))
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(width: 30, height: 30)
                            .background(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.red : Color.clear)
                            .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
            .frame(minHeight: mergedHeight)
            .background(lesson?.kind == .exam ? Color.orange.opacity(0.16) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var mergedHeight: CGFloat {
        let rowHeight: CGFloat = 86
        let rowSpacing: CGFloat = 16
        return (rowHeight * CGFloat(span)) + (rowSpacing * CGFloat(max(0, span - 1)))
    }
}
