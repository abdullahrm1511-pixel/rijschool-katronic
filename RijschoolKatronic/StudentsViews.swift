// Laadt SwiftUI voor schermen, knoppen, formulieren en navigatie.
import SwiftUI

// Leerlingen-tab met actieve en geslaagde leerlingen.
struct StudentsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var showGraduated = false
    @State private var showAddStudent = false

    // Filtert op status en zoektekst.
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
                NavigationLink {
                    FinanceOverviewView()
                } label: {
                    Label("Financiën", systemImage: "eurosign.circle")
                }

                // Segment wisselt tussen actieve en geslaagde leerlingen.
                Picker("Status", selection: $showGraduated) {
                    Text("Actief").tag(false)
                    Text("Geslaagd").tag(true)
                }
                .pickerStyle(.segmented)

                // Swipe naar links om een leerling te verwijderen.
                ForEach(filteredStudents) { student in
                    NavigationLink {
                        StudentDetailView(student: student)
                    } label: {
                        StudentRow(student: student, balance: store.balanceAmount(for: student))
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

// Compacte rij in de leerlingenlijst.
struct StudentRow: View {
    let student: Student
    let balance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(student.name).font(.headline)
            Text(student.phone.isEmpty ? student.email : student.phone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if balance > 0 {
                Text("EUR \(balance, specifier: "%.2f") open")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            } else if balance < 0 {
                Text("+ EUR \(abs(balance), specifier: "%.2f") tegoed")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
    }
}

// Detailpagina van een bestaande leerling.
struct StudentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State var student: Student
    @State private var selectedLesson: Lesson?
    @State private var showBirthDatePicker = false
    @State private var showTheoryDatePicker = false

    var body: some View {
        Form {
            // Persoonsgegevens en locaties van de leerling.
            Section("Leerling") {
                TextField("Adres", text: $student.address)
                if !navigationAddress(for: student).isEmpty {
                    MapsRouteMenu(address: navigationAddress(for: student))
                }
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

            // Status van leerling en theorie. Theorie-datum bepaalt automatisch verloop.
            Section("Status") {
                Picker("Leerling", selection: $student.status) {
                    ForEach(StudentStatus.allCases) { Text($0.rawValue).tag($0) }
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

            // De enige gewone vrije notitie van de leerling.
            Section("Notitie") {
                TextField("Notitie", text: $student.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Financieel totaal van deze leerling.
            Section("Openstaand") {
                let lessonPayments = store.lessons(for: student).filter { $0.kind == .lesson }
                let totalAmount = lessonPayments.reduce(0) { $0 + $1.amount }
                let paidAmount = lessonPayments.reduce(0) { $0 + $1.paidAmount }
                let balance = store.balanceAmount(for: student)
                Text(balance < 0 ? "+ EUR \(abs(balance), specifier: "%.2f")" : "EUR \(balance, specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundStyle(balance > 0 ? .red : .green)
                Text(balance < 0 ? "Tegoed" : "Openstaand bedrag")
                    .foregroundStyle(.secondary)
                Text("Totaal EUR \(totalAmount, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
                Text("Betaald EUR \(paidAmount, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
            }

            // Telt alle aangevinkte onderdelen over alle lessen van deze leerling.
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

            // Historie van alle lessen en examens van deze leerling.
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
                // Handmatig bewaren en terug naar vorige scherm.
                Button("Bewaar leerling") {
                    store.updateStudent(student)
                    dismiss()
                }
                // Verwijdert leerling en bijbehorende lessen.
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
            // Geboortedatum wordt met het iOS draaiwiel gekozen.
            DateWheelSheet(
                title: "Geboortedatum",
                date: Binding(
                    get: { parseBirthDate(student.birthDate) ?? defaultBirthDate },
                    set: { student.birthDate = formatBirthDate($0) }
                )
            )
        }
        .sheet(isPresented: $showTheoryDatePicker) {
            // Theorie behaald datum wordt ook met het iOS draaiwiel gekozen.
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
            // Automatisch opslaan als de gebruiker teruggaat.
            store.updateStudent(student)
        }
        .onChange(of: student) { updatedStudent in
            // Direct opslaan bij wijzigingen.
            store.updateStudent(updatedStudent)
        }
    }

    // Standaarddatum voor lege geboortedatum.
    private var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    // Theorie verloopt twee jaar na de behaalde datum.
    private var theoryExpiryDate: Date? {
        guard let passedDate = student.theoryPassedDate else { return nil }
        return Calendar.current.date(byAdding: .year, value: 2, to: passedDate)
    }
}

// Financieel overzicht van alle leerlingen.
struct FinanceOverviewView: View {
    @EnvironmentObject private var store: AppStore

    private var lessonStudents: [Student] {
        store.data.students.filter { student in
            !store.lessons(for: student).filter { $0.kind == .lesson }.isEmpty
        }
    }

    private var totalAmount: Double {
        store.data.lessons
            .filter { $0.kind == .lesson }
            .reduce(0) { $0 + $1.amount }
    }

    private var paidAmount: Double {
        store.paidAmount()
    }

    var body: some View {
        List {
            Section("Totaal") {
                Text("Openstaand EUR \(store.outstandingAmount(), specifier: "%.2f")")
                    .font(.title2.bold())
                    .foregroundStyle(store.outstandingAmount() > 0 ? .red : .green)
                Text("Totaal EUR \(totalAmount, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
                Text("Betaald EUR \(paidAmount, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
            }

            Section("Per leerling") {
                if lessonStudents.isEmpty {
                    Text("Nog geen lesbedragen")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lessonStudents) { student in
                        let studentLessons = store.lessons(for: student).filter { $0.kind == .lesson }
                        let totalAmount = studentLessons.reduce(0) { $0 + $1.amount }
                        let paidAmount = studentLessons.reduce(0) { $0 + $1.paidAmount }
                        let balance = store.balanceAmount(for: student)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(student.name).bold()
                            Text(balance < 0 ? "+ EUR \(abs(balance), specifier: "%.2f") tegoed" : "EUR \(balance, specifier: "%.2f") open")
                                .foregroundStyle(balance < 0 ? .green : balance > 0 ? .red : .secondary)
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
            }
        }
        .navigationTitle("Financiën")
    }
}

// Formulier voor het toevoegen van een nieuwe leerling.
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
                // Basisgegevens. Niet alles is verplicht; validatie staat onderaan.
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
                // Theorie kan direct bij nieuwe leerling ingevuld worden.
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
                    // Knop onderaan voor opslaan.
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

    // Alleen deze velden zijn verplicht bij een nieuwe leerling.
    private var missingFields: [String] {
        [
            ("Naam", name),
            ("Adres", address),
            ("Telefoon", phone),
            ("E-mail", email)
        ]
        .filter { $0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .map { $0.0 }
    }

    // Maakt de leerling aan of toont welke verplichte velden missen.
    // Functie die saveStudent uitvoert.
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

// Klein sheet-scherm met een echte iOS wheel datepicker.
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
