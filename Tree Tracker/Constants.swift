import Foundation

enum Constants {
    static let airtableApiKey = Bundle.main.infoDictionary?["AIRTABLE_API_KEY"] as! String
    static let airtableBaseId = Bundle.main.infoDictionary?["AIRTABLE_BASE_ID"] as! String
    static let airtableTreesTable = Bundle.main.infoDictionary?["AIRTABLE_TREES_TABLE_NAME"] as! String
    static let imgurClientId = Bundle.main.infoDictionary?["IMGUR_CLIENT_ID"] as! String
}
