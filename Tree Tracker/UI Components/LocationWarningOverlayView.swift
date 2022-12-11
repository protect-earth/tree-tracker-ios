import UIKit
import CoreLocation

class LocationWarningOverlayView: UIView, CLLocationManagerDelegate {

    // MARK: - Properties
     
    private let warningIconImageView = UIImageView()
    private let gpsAccuracyLabel = UILabel()
    private let locationManager = CLLocationManager()

    // MARK: - Initialization
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()

        self.isUserInteractionEnabled = false

        // Set up the warning icon image view
        warningIconImageView.image = .warningTriangle
        warningIconImageView.contentMode = .scaleAspectFit
        warningIconImageView.tintColor = .systemYellow
        addSubview(warningIconImageView)

        // Set up the GPS accuracy label
        gpsAccuracyLabel.textColor = .systemYellow
        gpsAccuracyLabel.font = UIFont.systemFont(ofSize: 14)
        gpsAccuracyLabel.text = "Establishing GPS Accuracy..."
        gpsAccuracyLabel.textAlignment = .center
        addSubview(gpsAccuracyLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateGPSAccuracy(accuracy: locations[0].horizontalAccuracy)
    }
    
    // MARK: - Layout
     
    override func layoutSubviews() {
        super.layoutSubviews()

        let orientation = UIDevice.current.orientation

        // Set the frame of the warning icon image view
        warningIconImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)

        // Set the frame of the GPS accuracy label
        gpsAccuracyLabel.sizeToFit()
        gpsAccuracyLabel.frame = CGRect(x: 0,
                                        y: warningIconImageView.frame.maxY + 30,
                                        width: gpsAccuracyLabel.frame.width,
                                        height:gpsAccuracyLabel.frame.height)

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
        print(accuracy)
        let accm = Int(round(accuracy))
        if accm > 5 {
            // Show the warning icon and set the text of the GPS accuracy label
            warningIconImageView.isHidden = false
            gpsAccuracyLabel.isHidden = false
            gpsAccuracyLabel.text = "GPS Accuracy: \(accm) m"
        } else {
            // Hide the warning icon and clear the text of the GPS accuracy label
            warningIconImageView.isHidden = true
            gpsAccuracyLabel.isHidden = true
        }
    }
}
