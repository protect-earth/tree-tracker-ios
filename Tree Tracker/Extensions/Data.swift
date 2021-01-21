import CommonCrypto
import Foundation

extension Data {
    func md5() -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
