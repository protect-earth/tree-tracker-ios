import UIKit
import RollbarNotifier

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = RollbarConfig()
        config.destination.accessToken = Secrets.rollbarAuthToken
        config.destination.environment = "local"
        config.setServerHost(nil, root: nil, branch: nil, codeVersion: "0.8.2")
        
        Rollbar.initWithConfiguration(config)
        Rollbar.infoMessage("See this message on your Rollbar Project Dashboard...")
        
        window = UIWindow()
        window?.rootViewController = MainFlowViewController()
        window?.makeKeyAndVisible()
        
        UITabBar.appearance().tintColor = UIColor(named: "PrimaryColor")
        UINavigationBar.appearance().tintColor = UIColor(named: "PrimaryColor")

        return true
    }
}

