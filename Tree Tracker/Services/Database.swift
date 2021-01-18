import Foundation
import GRDB

final class Database {
    private enum Constants {
        static let databaseUrl = URL.documentsDirectory.appendingPathComponent("db.sqlite")
    }

    private let dbQueue: DatabaseQueue?

    init() {
        self.dbQueue = try? DatabaseQueue(path: Constants.databaseUrl.path)

        try? createTablesIfNeeded()
    }

    private func createTablesIfNeeded() throws {
        try dbQueue?.write { db in
            guard try db.tableExists(Tree.databaseTableName) == false else { return }

            try db.create(table: Tree.databaseTableName) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("\(Tree.CodingKeys.notes.stringValue)", .text)
                table.column("\(Tree.CodingKeys.imageMd5.stringValue)", .text)
                table.column("\(Tree.CodingKeys.phImageId.stringValue)", .text)
                table.column("\(Tree.CodingKeys.remoteId.stringValue)", .integer)
                table.column("\(Tree.CodingKeys.species.stringValue)", .text)
                table.column("\(Tree.CodingKeys.supervisor.stringValue)", .text)
                table.column("\(Tree.CodingKeys.uploadDate.stringValue)", .datetime)
                table.uniqueKey([Tree.CodingKeys.phImageId.stringValue, Tree.CodingKeys.remoteId.stringValue], onConflict: .ignore)
            }
        }
    }

    func save(_ trees: [AirtableTree]) {
        save(trees.map { $0.toTree() })
    }

    func save(_ trees: [Tree]) {
        try? dbQueue?.write { db in
            trees.forEach { tree in
                do {
                    let potentialTree = try Tree.filter(
                        key: [
                            Tree.CodingKeys.phImageId.stringValue: tree.phImageId,
                            Tree.CodingKeys.remoteId.stringValue: tree.remoteId,
                        ])
                        .fetchOne(db)

                    if potentialTree == nil {
                        try tree.insert(db)
                    }
                } catch {
                    print("Tree: \(tree)")
                    print("Error when adding tree to DB. \(error)")
                }
            }
        }
    }

    func update(tree: Tree, with airtableTree: AirtableTree) {
        try? dbQueue?.write { db in
            var newTree = tree
            newTree.imageUrl = airtableTree.imageUrl
            newTree.uploadDate = airtableTree.uploadDate
            newTree.remoteId = airtableTree.id

            do {
                try newTree.update(db)
            } catch {
                print("Error when updating the tree with new info: \(error)")
            }
        }
    }

    func fetchAll(_ completion: @escaping ([Tree]) -> Void) {
        dbQueue?.read { db in
            let trees = try? Tree.fetchAll(db)
            completion(trees ?? [])
        }
    }

    func fetchTreesToSync(_ completion: @escaping ([Tree]) -> Void) {
        dbQueue?.read { db in
            let trees = try? Tree.filter(
                key: [
                    Tree.CodingKeys.uploadDate.stringValue: nil,
                    Tree.CodingKeys.remoteId.stringValue: nil,
                ])
                .fetchAll(db)
            completion(trees ?? [])
        }
    }
}
