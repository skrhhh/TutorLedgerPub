import Foundation
import SwiftData

@Model
final class PackageTransaction {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var hours: Int
    var amountCents: Int?
    var date: Date
    var note: String
    var createdAt: Date

    var student: Student?

    init(
        id: UUID = UUID(),
        type: PackageTransactionType,
        hours: Int,
        amountCents: Int? = nil,
        date: Date = .now,
        note: String = "",
        createdAt: Date = .now,
        student: Student? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.hours = hours
        self.amountCents = amountCents
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.student = student
    }

    var type: PackageTransactionType {
        get { PackageTransactionType(rawValue: typeRaw) ?? .adjust }
        set { typeRaw = newValue.rawValue }
    }
}
