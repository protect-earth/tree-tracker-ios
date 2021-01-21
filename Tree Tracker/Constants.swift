import Foundation

enum Constants {
    enum Airtable {
        static let apiKey = Bundle.main.infoDictionary?["AIRTABLE_API_KEY"] as! String
        static let baseId = Bundle.main.infoDictionary?["AIRTABLE_BASE_ID"] as! String
        static let treesTable = Bundle.main.infoDictionary?["AIRTABLE_TREES_TABLE_NAME"] as! String
    }
    enum Cloudinary {
        static let cloudName = Bundle.main.infoDictionary?["CLOUDINARY_CLOUD_NAME"] as! String
        static let uploadPresetName = Bundle.main.infoDictionary?["CLOUDINARY_UPLOAD_PRESET_NAME"] as! String
    }
}
