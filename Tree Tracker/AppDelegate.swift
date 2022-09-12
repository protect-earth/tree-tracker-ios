import UIKit
import RollbarNotifier

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = RollbarConfig()
        config.destination.accessToken = Secrets.rollbarAuthToken
        config.destination.environment = Constants.Http.protectEarthEnvironmentName

        Rollbar.initWithConfiguration(config)
        Rollbar.infoMessage("App startup")
        
        window = UIWindow()
        window?.rootViewController = MainFlowViewController()
        window?.makeKeyAndVisible()
        
        UITabBar.appearance().tintColor = UIColor(named: "PrimaryColor")
        UINavigationBar.appearance().tintColor = UIColor(named: "PrimaryColor")

        return true
    }
}

