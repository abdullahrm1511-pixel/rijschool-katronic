import Foundation

// Status waarmee leerlingen apart als actief of geslaagd getoond worden.
enum StudentStatus: String, Codable, CaseIterable, Identifiable {
    case actief = "Actief"
    case geslaagd = "Geslaagd"

    var id: String { rawValue }
}

// Staat nog in het model zodat oude opgeslagen data blijft openen.
enum HealthStatus: String, Codable, CaseIterable, Identifiable {
    case nietGestart = "Niet gestart"
    case aangevraagd = "Aangevraagd"
    case goedgekeurd = "Goedgekeurd"
    case extraBeoordeling = "Extra beoordeling"

    var id: String { rawValue }
}

// Theorie-status inclusief verlopen na twee jaar.
enum TheoryStatus: String, Codable, CaseIterable, Identifiable {
    case nietGestart = "Niet gestart"
    case bezig = "Bezig"
    case gehaald = "Gehaald"
    case verlopen = "Verlopen"

    var id: String { rawValue }
}

// Verschil tussen een gewone rijles en een examen in de agenda.
enum LessonKind: String, Codable {
    case lesson
    case exam
}

// Thema's die bij Instellingen gekozen kunnen worden.
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case donker = "Donker"
    case blauw = "Blauw"
    case licht = "Licht"

    var id: String { rawValue }
}

// Een rijonderdeel dat per les kan worden aangevinkt.
struct InstructionPart: Identifiable, Equatable {
    var id: Int
    var title: String
}

// Telt hoe vaak een rijonderdeel bij een leerling behandeld is.
struct TreatedPartCount: Identifiable, Equatable {
    var part: InstructionPart
    var count: Int

    var id: Int { part.id }
}

// Alfabetische lijst van alle rijonderdelen.
let instructionParts: [InstructionPart] = [
    InstructionPart(id: 18, title: "Achteruitrijden"),
    InstructionPart(id: 8, title: "Afslaan"),
    InstructionPart(id: 9, title: "Gedrag nabij en op kruispunten"),
    InstructionPart(id: 16, title: "Gedrag nabij en op bijzondere weggedeelten"),
    InstructionPart(id: 15, title: "Gedrag op rotondes"),
    InstructionPart(id: 17, title: "Hellingproef"),
    InstructionPart(id: 10, title: "Invoegen en uitvoegen"),
    InstructionPart(id: 11, title: "Inhalen en voorbijgaan"),
    InstructionPart(id: 20, title: "Keren"),
    InstructionPart(id: 19, title: "Parkeren"),
    InstructionPart(id: 12, title: "Tegemoetkomen en ingehaald worden"),
    InstructionPart(id: 6, title: "Rijden op rechte weggedeelten"),
    InstructionPart(id: 7, title: "Rijden en volgen van bochten"),
    InstructionPart(id: 2, title: "Schakelen"),
    InstructionPart(id: 21, title: "Stopproef"),
    InstructionPart(id: 3, title: "Stuurbehandeling"),
    InstructionPart(id: 13, title: "Wisselen van rijstrook"),
    InstructionPart(id: 5, title: "Wegrijden, verlaten van uitrit en rijden in inrit"),
    InstructionPart(id: 14, title: "Zijdelingse verplaatsingen"),
    InstructionPart(id: 1, title: "Zit- en stuurhouding, autogordel, spiegels")
].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

// Alle gegevens die bij een leerling horen.
struct Student: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var address: String
    var birthDate: String
    var phone: String
    var email: String
    var status: StudentStatus
    var healthStatus: HealthStatus
    var theoryStatus: TheoryStatus
    var theoryPassedDate: Date?
    var pickupAddress: String
    var schoolLocation: String
    var workLocation: String
    var notes: String
    var createdAt = Date()

    // Eigen init zodat nieuwe velden een standaardwaarde kunnen krijgen.
    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        birthDate: String,
        phone: String,
        email: String,
        status: StudentStatus,
        healthStatus: HealthStatus,
        theoryStatus: TheoryStatus,
        theoryPassedDate: Date? = nil,
        pickupAddress: String,
        schoolLocation: String = "",
        workLocation: String = "",
        notes: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.birthDate = birthDate
        self.phone = phone
        self.email = email
        self.status = status
        self.healthStatus = healthStatus
        self.theoryStatus = theoryStatus
        self.theoryPassedDate = theoryPassedDate
        self.pickupAddress = pickupAddress
        self.schoolLocation = schoolLocation
        self.workLocation = workLocation
        self.notes = notes
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case birthDate
        case phone
        case email
        case status
        case healthStatus
        case theoryStatus
        case theoryPassedDate
        case pickupAddress
        case schoolLocation
        case workLocation
        case notes
        case createdAt
    }

    // Leest ook oudere opgeslagen leerlingen zonder nieuwe velden netjes in.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        status = try container.decodeIfPresent(StudentStatus.self, forKey: .status) ?? .actief
        healthStatus = try container.decodeIfPresent(HealthStatus.self, forKey: .healthStatus) ?? .nietGestart
        theoryStatus = try container.decodeIfPresent(TheoryStatus.self, forKey: .theoryStatus) ?? .nietGestart
        theoryPassedDate = try container.decodeIfPresent(Date.self, forKey: .theoryPassedDate)
        pickupAddress = try container.decodeIfPresent(String.self, forKey: .pickupAddress) ?? ""
        schoolLocation = try container.decodeIfPresent(String.self, forKey: .schoolLocation) ?? ""
        workLocation = try container.decodeIfPresent(String.self, forKey: .workLocation) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

// Een ingeplande les of examen in de agenda.
struct Lesson: Identifiable, Codable, Equatable {
    var id = UUID()
    var studentId: UUID
    var kind: LessonKind
    var date: Date
    var startTime: String
    var endTime: String
    var note: String
    var amount: Double
    var paid: Bool
    var paidAmount: Double
    var treatedPartIds: [Int]
    var recurringSeriesId: UUID?
    var createdAt = Date()

    // Positief betekent dat er voor deze les nog iets openstaat.
    var remainingAmount: Double {
        amount - paidAmount
    }

    // Betaald bedrag wordt automatisch gevuld als een oude les alleen paid=true had.
    init(
        id: UUID = UUID(),
        studentId: UUID,
        kind: LessonKind,
        date: Date,
        startTime: String,
        endTime: String,
        note: String,
        amount: Double,
        paid: Bool,
        paidAmount: Double? = nil,
        treatedPartIds: [Int] = [],
        recurringSeriesId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.studentId = studentId
        self.kind = kind
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.note = note
        self.amount = amount
        self.paid = paid
        self.paidAmount = paidAmount ?? (paid ? amount : 0)
        self.treatedPartIds = treatedPartIds
        self.recurringSeriesId = recurringSeriesId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case studentId
        case kind
        case date
        case startTime
        case endTime
        case note
        case amount
        case paid
        case paidAmount
        case treatedPartIds
        case recurringSeriesId
        case createdAt
    }

    // Leest oudere lessen in en vult ontbrekende betaalde bedragen/onderdelen aan.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        studentId = try container.decode(UUID.self, forKey: .studentId)
        kind = try container.decode(LessonKind.self, forKey: .kind)
        date = try container.decode(Date.self, forKey: .date)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        amount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        paid = try container.decodeIfPresent(Bool.self, forKey: .paid) ?? false
        paidAmount = try container.decodeIfPresent(Double.self, forKey: .paidAmount) ?? (paid ? amount : 0)
        treatedPartIds = try container.decodeIfPresent([Int].self, forKey: .treatedPartIds) ?? []
        recurringSeriesId = try container.decodeIfPresent(UUID.self, forKey: .recurringSeriesId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

// Instellingen die de instructeur kan aanpassen.
struct AppSettings: Codable, Equatable {
    var theme: AppTheme = .donker
    var dayStartTime = "08:20"
    var dayEndTime = "18:00"
    var lessonMinutes = 50
    var defaultLessonAmount = 55.0
}

// Alles wat lokaal op de iPhone wordt bewaard.
struct AppData: Codable {
    var students: [Student] = []
    var lessons: [Lesson] = []
    var settings = AppSettings()
}
