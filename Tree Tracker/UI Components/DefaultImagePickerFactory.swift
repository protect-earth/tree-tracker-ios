import UIKit

class DefaultImagePickerFactory: ImagePickerFactory {
    
    func get() -> UIImagePickerController {
        let picker = RotatingUIImagePickerController()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = .camera
            // TODO
//            let overlay = CameraOverlayView(frame: (picker.cameraOverlayView?.frame)!)
//            picker.cameraOverlayView = overlay
        }
        return picker
    }
    
}
