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
}

extension UIImage {
    static var uploadIcon: UIImage { UIImage(named: "uploadIcon")! }
    static var listIcon: UIImage { UIImage(named: "listIcon")! }
    static var cameraIcon: UIImage { UIImage(named: "cameraIcon")! }
}
