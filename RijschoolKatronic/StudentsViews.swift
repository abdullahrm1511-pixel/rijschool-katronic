import SwiftUI

struct StudentsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var showGraduated = false
    @State private var showAddStudent = false

    private var filteredStudents: [Student] {
        store.data.students.filter { student in
            (showGraduated ? student.status == .geslaagd : student.status == .actief) &&
            (query.isEmpty || [
                student.name,
                student.phone,
                student.email,
                student.address,
                student.pickupAddress,
                student.schoolLocation,
                student.workLocation
            ].joined(separator: " ").localizedCaseInsensitiveContains(query))
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
    @State private var showBirthDatePicker = false
    @State private var showTheoryDatePicker = false

    var body: some View {
        Form {
            Section("Leerling") {
                TextField("Adres", text: $student.address)
                Button {
                    showBirthDatePicker = true
                } label: {
                    HStack {
                        Text("Geboortedatum")
                        Spacer()
                        Text(student.birthDate.isEmpty ? "Kies datum" : student.birthDate)
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Telefoon", text: $student.phone)
                TextField("E-mail", text: $student.email)
                TextField("Ophaaladres", text: $student.pickupAddress)
                TextField("Schoollocatie", text: $student.schoolLocation)
                TextField("Werklocatie", text: $student.workLocation)
                Text("Leeftijd: \(age(from: student.birthDate))")
            }

            Section("Status") {
                Picker("Leerling", selection: $student.status) {
                    ForEach(StudentStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Gezondheid", selection: $student.healthStatus) {
                    ForEach(HealthStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Theorie", selection: Binding(
                    get: { student.theoryStatus },
                    set: { newStatus in
                        student.theoryStatus = newStatus
                        if newStatus == .gehaald && student.theoryPassedDate == nil {
                            student.theoryPassedDate = Date()
                        }
                    }
                )) {
                    ForEach(TheoryStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                if student.theoryStatus == .gehaald || student.theoryStatus == .verlopen || student.theoryPassedDate != nil {
                    Button {
                        showTheoryDatePicker = true
                    } label: {
                        HStack {
                            Text("Theorie behaald op")
                            Spacer()
                            Text(student.theoryPassedDate.map(formatBirthDate) ?? "Kies datum")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let expiryDate = theoryExpiryDate {
                        Text("Verloopt op: \(formatDutchDate(expiryDate))")
                            .foregroundStyle(expiryDate <= Date() ? .red : .secondary)
                    }
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
                    dismiss()
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
        .sheet(isPresented: $showBirthDatePicker) {
            DateWheelSheet(
                title: "Geboortedatum",
                date: Binding(
                    get: { parseBirthDate(student.birthDate) ?? defaultBirthDate },
                    set: { student.birthDate = formatBirthDate($0) }
                )
            )
        }
        .sheet(isPresented: $showTheoryDatePicker) {
            DateWheelSheet(
                title: "Theorie behaald op",
                date: Binding(
                    get: { student.theoryPassedDate ?? Date() },
                    set: { newDate in
                        student.theoryPassedDate = newDate
                        if let expiryDate = Calendar.current.date(byAdding: .year, value: 2, to: newDate),
                           expiryDate <= Date() {
                            student.theoryStatus = .verlopen
                        } else if student.theoryStatus == .verlopen {
                            student.theoryStatus = .gehaald
                        }
                    }
                )
            )
        }
        .onDisappear {
            store.updateStudent(student)
        }
        .onChange(of: student) { updatedStudent in
            store.updateStudent(updatedStudent)
        }
    }

    private var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private var theoryExpiryDate: Date? {
        guard let passedDate = student.theoryPassedDate else { return nil }
        return Calendar.current.date(byAdding: .year, value: 2, to: passedDate)
    }
}

struct StudentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var name = ""
    @State private var address = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var phone = ""
    @State private var email = ""
    @State private var pickupAddress = ""
    @State private var schoolLocation = ""
    @State private var workLocation = ""
    @State private var theoryStatus: TheoryStatus = .nietGestart
    @State private var theoryPassedDate = Date()
    @State private var notes = ""
    @State private var showBirthDatePicker = false
    @State private var showTheoryDatePicker = false
    @State private var showMissingFields = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Naam", text: $name)
                TextField("Adres", text: $address)
                Button {
                    showBirthDatePicker = true
                } label: {
                    HStack {
                        Text("Geboortedatum")
                        Spacer()
                        Text(formatBirthDate(birthDate))
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Telefoon", text: $phone)
                TextField("E-mail", text: $email)
                TextField("Ophaaladres", text: $pickupAddress)
                TextField("Schoollocatie", text: $schoolLocation)
                TextField("Werklocatie", text: $workLocation)
                TextField("Notitie", text: $notes, axis: .vertical)
                Section("Theorie") {
                    Picker("Theorie", selection: $theoryStatus) {
                        ForEach(TheoryStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if theoryStatus == .gehaald || theoryStatus == .verlopen {
                        Button {
                            showTheoryDatePicker = true
                        } label: {
                            HStack {
                                Text("Theorie behaald op")
                                Spacer()
                                Text(formatBirthDate(theoryPassedDate))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button("Bewaar leerling") {
                        saveStudent()
                    }

                    Button("Annuleer") { dismiss() }
                }
            }
            .navigationTitle("Nieuwe leerling")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") { saveStudent() }
                }
            }
            .sheet(isPresented: $showBirthDatePicker) {
                DateWheelSheet(title: "Geboortedatum", date: $birthDate)
            }
            .sheet(isPresented: $showTheoryDatePicker) {
                DateWheelSheet(title: "Theorie behaald op", date: $theoryPassedDate)
            }
            .alert("Nog niet alles is ingevuld", isPresented: $showMissingFields) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vul nog in: \(missingFields.joined(separator: ", "))")
            }
        }
    }

    private var missingFields: [String] {
        [
            ("Naam", name),
            ("Adres", address),
            ("Telefoon", phone),
            ("E-mail", email),
            ("Ophaaladres", pickupAddress)
        ]
        .filter { $0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .map { $0.0 }
    }

    private func saveStudent() {
        guard missingFields.isEmpty else {
            showMissingFields = true
            return
        }
        store.addStudent(Student(
            name: name,
            address: address,
            birthDate: formatBirthDate(birthDate),
            phone: phone,
            email: email,
            status: .actief,
            healthStatus: .nietGestart,
            theoryStatus: theoryStatus,
            theoryPassedDate: theoryStatus == .gehaald || theoryStatus == .verlopen ? theoryPassedDate : nil,
            pickupAddress: pickupAddress,
            schoolLocation: schoolLocation,
            workLocation: workLocation,
            notes: notes
        ))
        dismiss()
    }
}

struct DateWheelSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date

    var body: some View {
        NavigationStack {
            DatePicker(title, selection: $date, displayedComponents: .date)
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
