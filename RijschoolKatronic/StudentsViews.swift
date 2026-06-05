import SwiftUI

struct StudentsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var showGraduated = false
    @State private var showAddStudent = false

    private var filteredStudents: [Student] {
        store.data.students.filter { student in
            (showGraduated ? student.status == .geslaagd : student.status == .actief) &&
            (query.isEmpty || [student.name, student.phone, student.email, student.address].joined(separator: " ").localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Status", selection: $showGraduated) {
                    Text("Actief").tag(false)
                    Text("Geslaagd").tag(true)
                }
                .pickerStyle(.segmented)

                ForEach(filteredStudents) { student in
                    NavigationLink {
                        StudentDetailView(student: student)
                    } label: {
                        StudentRow(student: student, outstanding: store.outstandingAmount(for: student))
                    }
                }
                .onDelete { offsets in
                    offsets.map { filteredStudents[$0] }.forEach(store.deleteStudent)
                }
            }
            .searchable(text: $query, prompt: "Zoek leerling")
            .navigationTitle("Leerlingen")
            .toolbar {
                Button {
                    showAddStudent = true
                } label: {
                    Label("Toevoegen", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showAddStudent) {
                StudentFormView()
            }
        }
    }
}

struct StudentRow: View {
    let student: Student
    let outstanding: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(student.name).font(.headline)
            Text(student.phone.isEmpty ? student.email : student.phone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if outstanding > 0 {
                Text("EUR \(outstanding, specifier: "%.2f") open")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
    }
}

struct StudentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State var student: Student
    @State private var selectedLesson: Lesson?

    var body: some View {
        Form {
            Section("Leerling") {
                TextField("Adres", text: $student.address)
                TextField("Telefoon", text: $student.phone)
                TextField("E-mail", text: $student.email)
                TextField("Ophaaladres", text: $student.pickupAddress)
                Text("Leeftijd: \(age(from: student.birthDate))")
            }

            Section("Status") {
                Picker("Leerling", selection: $student.status) {
                    ForEach(StudentStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Gezondheid", selection: $student.healthStatus) {
                    ForEach(HealthStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Theorie", selection: $student.theoryStatus) {
                    ForEach(TheoryStatus.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section("Notitie") {
                TextField("Notitie", text: $student.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Openstaand") {
                let lessonPayments = store.lessons(for: student).filter { $0.kind == .lesson }
                let totalAmount = lessonPayments.reduce(0) { $0 + $1.amount }
                let paidAmount = lessonPayments.reduce(0) { $0 + $1.paidAmount }
                Text("EUR \(store.outstandingAmount(for: student), specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundStyle(store.outstandingAmount(for: student) > 0 ? .red : .green)
                Text("Totaal EUR \(totalAmount, specifier: "%.2f") - betaald EUR \(paidAmount, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
            }

            Section("Totaal onderdelen") {
                let counts = store.treatedPartCounts(for: student)
                if counts.isEmpty {
                    Text("Nog geen behandelde onderdelen")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(counts) { item in
                        HStack {
                            Text(item.part.title)
                            Spacer()
                            Text("\(item.count)x")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Alle lessen") {
                let lessons = store.lessons(for: student)
                if lessons.isEmpty {
                    Text("Nog geen lessen")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lessons) { lesson in
                        Button {
                            selectedLesson = lesson
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(formatDutchDate(lesson.date)) - \(lesson.startTime)-\(lesson.endTime)")
                                    .foregroundStyle(.primary)
                                Text(lesson.kind == .exam ? "Examen" : "Les - EUR \(lesson.amount, specifier: "%.2f") - betaald EUR \(lesson.paidAmount, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Bewaar leerling") {
                    store.updateStudent(student)
                }
                Button(role: .destructive) {
                    store.deleteStudent(student)
                    dismiss()
                } label: {
                    Text("Verwijder leerling")
                }
            }
        }
        .navigationTitle(student.name)
        .sheet(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
        }
        .onDisappear {
            store.updateStudent(student)
        }
    }
}

struct StudentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var name = ""
    @State private var address = ""
    @State private var birthDate = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var pickupAddress = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Naam", text: $name)
                TextField("Adres", text: $address)
                TextField("Geboortedatum", text: $birthDate)
                TextField("Telefoon", text: $phone)
                TextField("E-mail", text: $email)
                TextField("Ophaaladres", text: $pickupAddress)
                TextField("Notitie", text: $notes, axis: .vertical)

                Section {
                    Button("Bewaar leerling") {
                        store.addStudent(Student(
                            name: name,
                            address: address,
                            birthDate: birthDate,
                            phone: phone,
                            email: email,
                            status: .actief,
                            healthStatus: .nietGestart,
                            theoryStatus: .nietGestart,
                            pickupAddress: pickupAddress,
                            notes: notes
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Annuleer") { dismiss() }
                }
            }
            .navigationTitle("Nieuwe leerling")
        }
    }
}
