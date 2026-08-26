import Foundation
import SwiftData

enum TutorLedgerSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Student.self, LessonRecord.self, Bill.self, PackageTransaction.self]
    }
}

enum TutorLedgerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TutorLedgerSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}

enum ModelContainerFactory {
    private static let configurationName = "TutorLedgerLocal"

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: TutorLedgerSchemaV1.self)
        return try buildContainer(schema: schema)
    }

    static func makeInMemoryFallbackContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: TutorLedgerSchemaV1.self)
        let configuration = ModelConfiguration(
            "TutorLedgerFallback",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: TutorLedgerMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func buildContainer(schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            configurationName,
            schema: schema,
            url: storeURL(),
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: TutorLedgerMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            NSLog("TutorLedger: ModelContainer load failed (\(error.localizedDescription)), resetting store.")
            try resetStore()
            return try ModelContainer(
                for: schema,
                migrationPlan: TutorLedgerMigrationPlan.self,
                configurations: [configuration]
            )
        }
    }

    private static func applicationSupportDirectory() throws -> URL {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ModelContainerFactoryError.missingApplicationSupportDirectory
        }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func storeURL() -> URL {
        let base = (try? applicationSupportDirectory()) ?? FileManager.default.temporaryDirectory
        return base.appending(path: "\(configurationName).store", directoryHint: .isDirectory)
    }

    private static func resetStore() throws {
        let storeDirectory = storeURL()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: storeDirectory.path) {
            try fileManager.removeItem(at: storeDirectory)
        }
        for suffix in ["-shm", "-wal"] {
            let sidecar = URL(fileURLWithPath: storeDirectory.path + suffix)
            if fileManager.fileExists(atPath: sidecar.path) {
                try fileManager.removeItem(at: sidecar)
            }
        }
    }
}

enum ModelContainerFactoryError: LocalizedError {
    case missingApplicationSupportDirectory

    var errorDescription: String? {
        switch self {
        case .missingApplicationSupportDirectory:
            return String(localized: "无法访问应用数据目录")
        }
    }
}

enum AppModelContainerBootstrap {
    case ready(container: ModelContainer, isInMemoryFallback: Bool)
    case failed(message: String)

    static func load() -> AppModelContainerBootstrap {
        do {
            return .ready(
                container: try ModelContainerFactory.makeContainer(),
                isInMemoryFallback: false
            )
        } catch {
            NSLog("TutorLedger: persistent ModelContainer failed: \(error.localizedDescription)")
            do {
                let container = try ModelContainerFactory.makeInMemoryFallbackContainer()
                return .ready(container: container, isInMemoryFallback: true)
            } catch {
                return .failed(message: error.localizedDescription)
            }
        }
    }
}
