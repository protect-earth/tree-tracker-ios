import CommonCrypto
import UIKit

extension UIImage {
    func md5() -> String? {
        guard let data = self.pngData() else { return nil }

        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        data.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static var uploadIcon: UIImage {
        return UIImage(named: "uploadIcon")!
    }

    static var listIcon: UIImage {
        return UIImage(named: "listIcon")!
    }
}
