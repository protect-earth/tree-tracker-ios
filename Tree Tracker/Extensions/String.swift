import Foundation
import CommonCrypto

extension String {
    func sha256() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }

        let length = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
