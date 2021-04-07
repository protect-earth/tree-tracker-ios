import Foundation
import GRDB

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

        try? createTablesAndMigrateIfNeeded()
    }

    private func createTablesAndMigrateIfNeeded() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.alter(table: RemoteTree.databaseTableName) { table in
                let column = table.add(column: RemoteTree.CodingKeys.sentFromThisDevice.stringValue, .boolean)
                column.defaults(to: false)
            }
        }
        
        try dbQueue?.write { db in
            if try db.tableExists(RemoteTree.databaseTableName) == false {
                try db.create(table: RemoteTree.databaseTableName) { table in
                    table.column(RemoteTree.CodingKeys.id.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.supervisor.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.species.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.site.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.notes.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.coordinates.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.what3words.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.imageUrl.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.thumbnailUrl.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.imageMd5.stringValue, .text)
                    table.column(RemoteTree.CodingKeys.uploadDate.stringValue, .date)
                    table.column(RemoteTree.CodingKeys.createDate.stringValue, .date)
                    table.column(RemoteTree.CodingKeys.sentFromThisDevice.stringValue, .boolean)

                    table.primaryKey([RemoteTree.CodingKeys.id.stringValue])
                }
            }

            if try db.tableExists(LocalTree.databaseTableName) == false {
                try db.create(table: LocalTree.databaseTableName) { table in
                    table.column(LocalTree.CodingKeys.phImageId.stringValue, .text)
                    table.column(LocalTree.CodingKeys.createDate.stringValue, .date)
                    table.column(LocalTree.CodingKeys.supervisor.stringValue, .text)
                    table.column(LocalTree.CodingKeys.species.stringValue, .text)
                    table.column(LocalTree.CodingKeys.site.stringValue, .text)
                    table.column(LocalTree.CodingKeys.notes.stringValue, .text)
                    table.column(LocalTree.CodingKeys.coordinates.stringValue, .text)
                    table.column(LocalTree.CodingKeys.what3words.stringValue, .text)
                    table.column(LocalTree.CodingKeys.imageMd5.stringValue, .text)

                    table.primaryKey([LocalTree.CodingKeys.phImageId.stringValue])
                }
            }

            if try db.tableExists(Site.databaseTableName) == false {
                try db.create(table: Site.databaseTableName) { table in
                    table.column(Site.CodingKeys.id.stringValue, .text)
                    table.column(Site.CodingKeys.name.stringValue, .text)

                    table.primaryKey([Site.CodingKeys.id.stringValue])
                }
            }

            if try db.tableExists(Supervisor.databaseTableName) == false {
                try db.create(table: Supervisor.databaseTableName) { table in
                    table.column(Supervisor.CodingKeys.id.stringValue, .text)
                    table.column(Supervisor.CodingKeys.name.stringValue, .text)

                    table.primaryKey([Supervisor.CodingKeys.id.stringValue])
                }
            }

            if try db.tableExists(Species.databaseTableName) == false {
                try db.create(table: Species.databaseTableName) { table in
                    table.column(Species.CodingKeys.id.stringValue, .text)
                    table.column(Species.CodingKeys.name.stringValue, .text)

                    table.primaryKey([Species.CodingKeys.id.stringValue])
                }
            }
            
//            if let dbQueue = dbQueue, try !migrator.hasCompletedMigrations(db) {
//                logger.log(.database, "Needs migration - starting...")
//                try migrator.migrate(dbQueue)
//                logger.log(.database, "Migration finished succesfully!")
//            }
        }
    }

    func save(_ trees: [AirtableTree], sentFromThisDevice: Bool) {
        try? dbQueue?.write { db in
            trees.forEach { tree in
                let tree = tree.toRemoteTree(sentFromThisDevice: sentFromThisDevice)
                do {
                    let potentialTree = try RemoteTree
                        .filter(key: tree.id)
                        .fetchOne(db)

                    if potentialTree == nil {
                        try tree.insert(db)
                    }
                } catch {
                    logger.log(.database, "Tree: \(tree)")
                    logger.log(.database, "Error when adding remote tree to DB. \(error)")
                }
            }
        }
    }

    func save(_ trees: [LocalTree]) {
        try? dbQueue?.write { db in
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
    }

    func save<T: Identifiable & TableRecord & FetchableRecord & PersistableRecord>(_ models: [T]) where T.ID: DatabaseValueConvertible {
        try? dbQueue?.write { db in
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
        } completion: { db, result in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func remove(tree: LocalTree, completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? tree.delete(db)
        } completion: { db, result in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func removeLocalTrees(completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? LocalTree.deleteAll(db)
        } completion: { db, result in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func update(tree: LocalTree, completion: @escaping () -> Void) {
        dbQueue?.asyncWrite { db in
            try? tree.update(db)
        } completion: { db, result in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func fetchRemoteTrees(_ completion: @escaping ([RemoteTree]) -> Void) {
        dbQueue?.read { db in
            let trees = try? RemoteTree.fetchAll(db)
            DispatchQueue.main.async {
                completion(trees ?? [])
            }
        }
    }
    
    func fetchUploadedTrees(_ completion: @escaping ([RemoteTree]) -> Void) {
        dbQueue?.read { db in
            let trees = try? RemoteTree.filter(Column(RemoteTree.CodingKeys.sentFromThisDevice.rawValue) == true).fetchAll(db)
            DispatchQueue.main.async {
                completion(trees ?? [])
            }
        }
    }

    func fetchLocalTrees(_ completion: @escaping ([LocalTree]) -> Void) {
        dbQueue?.read { db in
            let trees = try? LocalTree.fetchAll(db)
            DispatchQueue.main.async {
                completion(trees ?? [])
            }
        }
    }

    func fetch<T: Identifiable & TableRecord & FetchableRecord & PersistableRecord>(_ type: T, completion: @escaping ([T]) -> Void) {
        dbQueue?.read { db in
            let models = try? T.fetchAll(db)
            DispatchQueue.main.async {
                completion(models ?? [])
            }
        }
    }
    
    func fetch<T, U>(_ type1: T.Type, _ type2: U.Type, completion: @escaping ([T], [U]) -> Void) where
        T: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        U: Identifiable & TableRecord & FetchableRecord & PersistableRecord {
        dbQueue?.read { db in
            let models1 = (try? T.fetchAll(db)) ?? []
            let models2 = (try? U.fetchAll(db)) ?? []
            DispatchQueue.main.async {
                completion(models1, models2)
            }
        }
    }

    func fetch<T, U, V>(_ type1: T.Type, _ type2: U.Type, _ type3: V.Type, completion: @escaping ([T], [U], [V]) -> Void) where
        T: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        U: Identifiable & TableRecord & FetchableRecord & PersistableRecord,
        V: Identifiable & TableRecord & FetchableRecord & PersistableRecord {
        dbQueue?.read { db in
            let models1 = (try? T.fetchAll(db)) ?? []
            let models2 = (try? U.fetchAll(db)) ?? []
            let models3 = (try? V.fetchAll(db)) ?? []
            DispatchQueue.main.async {
                completion(models1, models2, models3)
            }
        }
    }
}
