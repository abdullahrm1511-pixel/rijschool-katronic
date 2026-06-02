import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }

            StudentsView()
                .tabItem { Label("Leerlingen", systemImage: "person.2") }

            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
        }
        .tint(.blue)
    }
}

struct AgendaView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDate = Date()
    @State private var bookingSlot: (String, String)?
    @State private var selectedLesson: Lesson?

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
                        let lesson = store.lessons(on: selectedDate).first { $0.startTime == slot.0 }
                        AgendaRow(
                            startTime: slot.0,
                            endTime: slot.1,
                            lesson: lesson,
                            student: lesson.flatMap { store.student(for: $0) }
                        )
                        .onTapGesture {
                            if let lesson {
                                selectedLesson = lesson
                            } else {
                                bookingSlot = slot
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Agenda")
            .toolbar {
                Button("Vandaag") { selectedDate = Date() }
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
            .sheet(isPresented: Binding(
                get: { bookingSlot != nil },
                set: { if !$0 { bookingSlot = nil } }
            )) {
                if let bookingSlot {
                    BookingSheet(date: selectedDate, startTime: bookingSlot.0, endTime: bookingSlot.1)
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
                    Text("\(exam.startTime) · \(store.student(for: exam)?.name ?? "Leerling")")
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

struct AgendaRow: View {
    let startTime: String
    let endTime: String
    let lesson: Lesson?
    let student: Student?

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
                        Text(lesson.kind == .exam ? "Examen" : lesson.paid ? "Betaald" : "Open")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(lesson.kind == .exam ? Color.orange : lesson.paid ? Color.green : Color.red)
                            .clipShape(Capsule())
                    }
                    Text(lesson.kind == .exam ? "Examen ingepland" : student.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if lesson.kind == .lesson {
                        Text("EUR \(lesson.amount, specifier: "%.2f")")
                            .font(.caption.bold())
                    }
                } else {
                    Text("Vrije plek").font(.headline)
                    Text("Tik om te plannen").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(lesson?.kind == .exam ? Color.orange.opacity(0.16) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
