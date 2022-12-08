import UIKit
import CoreLocation

class LocationWarningOverlayView: UIView {
    
    // MARK: - Properties
    
    let warningIconImageView = UIImageView()
    let gpsAccuracyLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        // Set up the warning icon image view
        warningIconImageView.image = .warningTriangle
        warningIconImageView.contentMode = .scaleAspectFit
        warningIconImageView.tintColor = .yellow
        addSubview(warningIconImageView)
        
        // Set up the GPS accuracy label
        gpsAccuracyLabel.textColor = .yellow
        gpsAccuracyLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(gpsAccuracyLabel)
        
        updateGPSAccuracy(accuracy: CLLocationAccuracy(integerLiteral: 5))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let orientation = UIDevice.current.orientation
        
        // Set the frame of the warning icon image view
        warningIconImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        // Set the frame of the GPS accuracy label
        gpsAccuracyLabel.sizeToFit()
        gpsAccuracyLabel.frame = CGRect(x: 0, y: warningIconImageView.frame.maxY + 30, width: gpsAccuracyLabel.frame.width, height: gpsAccuracyLabel.frame.height)
        
        if orientation == .portrait || orientation == .portraitUpsideDown {
            warningIconImageView.center = CGPoint(x: frame.midX, y: frame.midY - 50)
            gpsAccuracyLabel.center = CGPoint(x: frame.midX, y: frame.midY)
        } else {
            warningIconImageView.center = CGPoint(x: frame.midY, y: frame.midX - 50)
            gpsAccuracyLabel.center = CGPoint(x: frame.midY, y: frame.midX)
        }
    }
    
    // MARK: - GPS Accuracy
    
    func updateGPSAccuracy(accuracy: CLLocationAccuracy) {
        if accuracy > 0 && accuracy < 10 {
            // Show the warning icon and set the text of the GPS accuracy label
            warningIconImageView.isHidden = false
            gpsAccuracyLabel.text = "GPS Accuracy: LOW"
        } else {
            // Hide the warning icon and clear the text of the GPS accuracy label
            warningIconImageView.isHidden = true
            gpsAccuracyLabel.text = ""
        }
    }
}
