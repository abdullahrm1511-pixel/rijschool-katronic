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
    @EnvironmentObject private var store: AppStore
    @State var student: Student

    var body: some View {
        Form {
            Section("Leerling") {
                Text(student.address)
                Text(student.phone)
                Text(student.email)
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
                Text(student.notes.isEmpty ? "-" : student.notes)
            }
        }
        .navigationTitle(student.name)
        .toolbar {
            Button("Bewaar") {
                store.updateStudent(student)
            }
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
            }
            .navigationTitle("Nieuwe leerling")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
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
                }
            }
        }
    }
}
