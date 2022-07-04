import Foundation
import CryptoKit

extension Data {
    func md5() -> String {
        let computed = Insecure.MD5.hash(data: self)
        return computed.map { String(format: "%02x", $0) }.joined()
    }
}
