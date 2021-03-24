import Foundation

enum Constants {
    enum Airtable {
        static let apiKey = Secrets.airtableApiKey
        static let baseId = Secrets.airtableBaseId
        static let treesTable = Secrets.airtableTreesTableName
        static let sitesTable = Secrets.airtableSitesTableName
        static let supervisorsTable = Secrets.airtableSupervisorsTableName
        static let speciesTable = Secrets.airtableSpeciesTableName
    }
    enum Cloudinary {
        static let cloudName = Secrets.cloudinaryCloudName
        static let uploadPresetName = Secrets.cloudinaryUploadPresetName
    }
}
