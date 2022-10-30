import Foundation
import UIKit

/*
 This view is used to display accuracy warnings as an overlay to the main camera view
 */
class CameraOverlayView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let toolbar = UIToolbar()
//        toolbar.barStyle = .default
//        toolbar.backgroundColor = .white
//        toolbar.barTintColor = .blue
        toolbar.isTranslucent = true
        toolbar.setItems([UIBarButtonItem(image: .warningTriangle)], animated: false)
        toolbar.frame = CGRect(x: 0, y: 0, width: frame.width, height: 100)
//        toolbar.sizeToFit()
        self.addSubview(toolbar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder) is not implemented!")
    }
    
}
