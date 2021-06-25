import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.rootViewController = MainFlowViewController()
        window?.makeKeyAndVisible()
        
        UITabBar.appearance().tintColor = UIColor(named: "PrimaryColor")
        UINavigationBar.appearance().tintColor = UIColor(named: "PrimaryColor")

        return true
    }
}

