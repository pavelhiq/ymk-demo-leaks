import UIKit
import os
import YandexMapsMobile

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - State
    var window: UIWindow?
    
    private var isApplicationConfigured = false
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        configureApplication()
        
        let screenSize = UIScreen.main.bounds
        self.window = UIWindow(frame: screenSize)

        let rootViewController = buildViewHierarchy()

        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        YMKMapKit.sharedInstance().onStart()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        YMKMapKit.sharedInstance().onStop()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        os_log(
            "Did receive memory warning!",
            log: OSLog.mapkitLog,
            type: .default
        )
    }
    
    // MARK: - Internals
    
    private func configureApplication() {
        guard !isApplicationConfigured else { return }
        isApplicationConfigured = true
        
        configureYandexMapKit()
    }
    
    private func buildViewHierarchy() -> UIViewController {
        let rootViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
                
        return navigationController
    }
    
    private func configureYandexMapKit() {
        YMKMapKit.setApiKey("MAPKIT_API_KEY")
        YMKMapKit.setLocale("ru_RU")
        
        
        let mapKitInstance = YMKMapKit.sharedInstance()
        mapKitInstance.storageManager.setMaxTileStorageSizeWithLimit(50 * 1024 * 1024) { bytes, error in
            if let error = error {
                os_log(
                    "Failed to set tile storage size limit: %{public}@",
                    log: OSLog.mapkitLog,
                    type: .default,
                    error.localizedDescription
                )
            }
            if let bytes = bytes {
                os_log(
                    "Did set tile storage size limit to %{public}.2f Mb",
                    log: OSLog.mapkitLog,
                    type: .default,
                    Double(truncating: bytes) / Double(1024 * 1024)
                )
            }
        }
    }

}
