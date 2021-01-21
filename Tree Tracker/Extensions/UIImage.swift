import CommonCrypto
import UIKit

extension UIImage {
    func md5() -> String? {
        guard let data = self.pngData() else { return nil }

        return data.md5()
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
