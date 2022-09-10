import Foundation

// Minimal specification - see Cloudinary API docs for full schema
struct CloudinaryUploadResponse: Codable {
    let secureUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case secureUrl = "secure_url"
    }
}
