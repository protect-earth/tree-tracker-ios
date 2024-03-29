import Foundation
import GRDB
import RollbarNotifier

private extension LogCategory {
    static var database = LogCategory(name: "Database")
}

final class Database {
    private enum Constants {
        static let databaseUrl = URL.documentsDirectory.appendingPathComponent("db.sqlite")
    }

    private let dbQueue: DatabaseQueue?
    private let logger: Logging

    init(logger: Logging = CurrentEnvironment.logger) {
        self.dbQueue = try? DatabaseQueue(path: Constants.databaseUrl.path)
        self.logger = logger

        try? prepareSchema()
    }

    private func prepareSchema() throws {
        
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true
        
        // Reset migration removes all legacy db objects
        // to prepare for new schema fully managed by migrations
        migrator.registerMigration("reset") { db in
            for table in ["remoteTree", "localTree", "site", "supervisor", "species"] {
                if try db.tableExists(table) {
                    try db.drop(table: table)
                }
            }
        }
        
        // 1.0 migration adds db objects fully via migration
        migrator.registerMigration("1.0") { db in
            try db.create(table: "localTree") { table in
                table.column("treeId", .text)
                table.column("phImageId", .text)
                table.column("createDate", .date)
                table.column("supervisor", .text)
                table.column("species", .text)
                table.column("site", .text)
                table.column("coordinates", .text)
                table.column("imageMd5", .text)
                
                table.primaryKey(["treeId"])
            }

            try db.create(table: "site") { table in
                table.column("id", .text)
                table.column("name", .text)

                table.primaryKey(["id"])
            }

            try db.create(table: "supervisor") { table in
                table.column("id", .text)
                table.column("name", .text)

                table.primaryKey(["id"])
            }

            try db.create(table: "species") { table in
                table.column("id", .text)
                table.column("name", .text)

                table.primaryKey(["id"])
            }
        }
        
        // 1.1 migration adds uploadedTree table to track uploads and allow local cleanup
        migrator.registerMigration("1.1") { db in
            try db.create(table: "uploadedTree") { table in
                table.column("id", .text)
                table.column("phImageId", .text)
                table.column("uploadDate", .date)

                table.primaryKey(["id"])
            }
        }
        
        guard let dbQueue = dbQueue else { return }
        var needsMigration = false
        var alreadyAppliedMigrations: Set<String> = []

        try dbQueue.read() { db in
            needsMigration = try !migrator.hasCompletedMigrations(db)
            alreadyAppliedMigrations = try migrator.appliedIdentifiers(db)
        }
        
        logger.log("Migrations previously applied: \(alreadyAppliedMigrations)")
        
        if needsMigration {
            do {
                try migrator.migrate(dbQueue)
            } catch {
                Rollbar.criticalError(error)
                fatalError("Unable to complete schema preparation: \(error)")
            }
            try dbQueue.read() { db in
                let appliedMigrations = try migrator.completedMigrations(db)
                Rollbar.infoMessage("Successfully completed database migration",
                                    data: ["migrationsApplied": appliedMigrations.description])
                logger.log(.database, "Database migration completed. Cumulative applied migrations: \(appliedMigrations)")
            }
        } else {
            Rollbar.infoMessage("Database migration was not required",
                                data: ["alreadyAppliedMigrations": alreadyAppliedMigrations.description])
        }
    }

    func save(_ trees: [LocalTree]) {
        do {
            try dbQueue?.write { db in
                trees.forEach { tree in
                    do {
                        let potentialTree = try LocalTree
                            .filter(key: tree.phImageId)
                            .fetchOne(db)

                        if potentialTree == nil {
                            try tree.insert(db)
                        }
                    } catch {
                        logger.log(.database, "Tree: \(tree)")
                        logger.log(.database, "Error when adding tree to DB. \(error)")
                    }
                }
            }
        } catch {
            logger.log(.database, "Error when adding tree to DB. \(error)")
        }
    }

    func save<T: Identifiable & TableRecord & FetchableRecord & PersistableRecord>(_ models: [T]) where T.ID: DatabaseValueConvertible {
        do {
            try dbQueue?.write { db in
                models.forEach { model in
                    do {
                        let potentialModel = try T
                            .filter(key: model.id)
                            .fetchOne(db)

                        if potentialModel == nil {
                            try model.insert(db)
                        }

                        logger.log(.database, "Saved: \(model)")
                    } catch {
                        logger.log(.database, "Model: \(model)")
                        logger.log(.database, "Error when adding model to DB. \(error)")
                    }
                }
            }
        } catch {
            logger.log(.database, "Error when adding model to DB. \(error)")
        }
    }
    
    /// Remove all current content and replace it with the following.
    func replace<T: Identifiable & TableRecord & FetchableRecord & PersistableRecord>(_ models: [T], completion: @escaping () -> Void) where T.ID: DatabaseValueConvertible {
        dbQueue?.asyncWrite { [weak self] db in
            try T.deleteAll(db)
            self?.logger.log(.database, "Removed all \(T.self) in preparation of new content.")
            models.forEach { model in
                do {
                    try model.insert(db)
                    self?.logger.log(.database, "Added: \(model)")
                } catch {
                    self?.logger.log(.database, "Model: \(model)")
                    self?.logger.log(.database, "Error when adding model to DB. \(error)")
                }
            }
        } completion: { [weak self] db, result in
            if case let .failure(error) = result {
                self?.logger.log(.database, "Error when adding model to DB. \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func remove(tree: LocalTree, completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? tree.delete(db)
        } completion: { [weak self] db, result in
            if case let .failure(error) = result {
                self?.logger.log(.database, "Error when removing tree from DB. \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func removeLocalTrees(completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? LocalTree.deleteAll(db)
        } completion: { [weak self] db, result in
            if case let .failure(error) = result {
                self?.logger.log(.database, "Error when removing local trees from DB. \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func clearUploadedItems(completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? UploadedTree.deleteAll(db)
        } completion: { db, result in
            switch result {
            case .failure(let error):
                Rollbar.errorError(error, data: nil, context: "Error deleting uploaded items")
            default:
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func update(tree: LocalTree, completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? tree.update(db)
        } completion: { [weak self] db, result in
            if case let .failure(error) = result {
                self?.logger.log(.database, "Error when updating tree in DB. \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func fetchLocalTrees(_ completion: @escaping ([LocalTree]) -> Void) {
        do {
            try dbQueue?.read { db in
                let trees = try? LocalTree.fetchAll(db)
                DispatchQueue.main.async {
                    completion(trees ?? [])
                }
            }
        } catch {
            logger.log(.database, "Error when fetching local trees from DB. \(error)")
        }
    }

    func fetch<T: Identifiable & TableRecord & FetchableRecord & PersistableRecord>(_ type: T, completion: @escaping ([T]) -> Void) {
        do {
            try dbQueue?.read { db in
                let models = try? T.fetchAll(db)
                DispatchQueue.main.async {
                    completion(models ?? [])
                }
            }
        } catch {
            logger.log(.database, "Error when fetching type \(String(describing: T.self)) from DB. \(error)")
        }
    }
    
    func fetchAll<T>(_ type1: T.Type, completion: @escaping ([T]) -> Void) where T: Identifiable & TableRecord & FetchableRecord & PersistableRecord {
        do {
            try dbQueue?.read { db in
                let models1 = (try? T.fetchAll(db)) ?? []
                DispatchQueue.main.async {
                    completion(models1)
                }
            }
        } catch {
            logger.log(.database, "Error when fetching type \(T.self) from DB. \(error)")
        }
    }
    
    func fetch<T, U>(_ type1: T.Type, _ type2: U.Type, completion: @escaping ([T], [U]) -> Void) where
        T: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        U: Identifiable & TableRecord & FetchableRecord & PersistableRecord {
        do {
            try dbQueue?.read { db in
                let models1 = (try? T.fetchAll(db)) ?? []
                let models2 = (try? U.fetchAll(db)) ?? []
                DispatchQueue.main.async {
                    completion(models1, models2)
                }
            }
        } catch {
            logger.log(.database, "Error when fetching types \([T.self, U.self].map(String.init(describing:)).joined(separator: ", ")) from DB. \(error)")
        }
    }

    func fetch<T, U, V>(_ type1: T.Type, _ type2: U.Type, _ type3: V.Type, completion: @escaping ([T], [U], [V]) -> Void) where
        T: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        U: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        V: Identifiable & TableRecord & FetchableRecord & PersistableRecord {
        do {
            try dbQueue?.read { db in
                let models1 = (try? T.fetchAll(db)) ?? []
                let models2 = (try? U.fetchAll(db)) ?? []
                let models3 = (try? V.fetchAll(db)) ?? []
                DispatchQueue.main.async {
                    completion(models1, models2, models3)
                }
            }
        } catch {
            logger.log(.database, "Error when fetching types \([T.self, U.self, V.self].map(String.init(describing:)).joined(separator: ", ")) from DB. \(error)")
        }
    }
}
