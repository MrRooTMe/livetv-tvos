import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let api = LiveBoxAPI()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let window = self.window ?? UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.makeKeyAndVisible()

        guard let activationCode = KeychainStore.shared.activationCode, !activationCode.isEmpty else {
            presentLogin(from: storyboard, on: window, animated: false)
            return true
        }

        if window.rootViewController == nil {
            window.rootViewController = storyboard.instantiateInitialViewController()
        }

        api.verifyActivation(code: activationCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(true):
                    window.rootViewController = storyboard.instantiateInitialViewController()
                case .success(false):
                    KeychainStore.shared.removeActivationCode()
                    self.presentLogin(from: storyboard, on: window, animated: true)
                case .failure:
                    self.presentInternetError(from: storyboard, on: window)
                }
            }
        }

        return true
    }

    private func presentLogin(from storyboard: UIStoryboard, on window: UIWindow, animated: Bool) {
        let loginController = storyboard.instantiateViewController(withIdentifier: "login")
        let navigationController = UINavigationController(rootViewController: loginController)
        navigationController.setNavigationBarHidden(true, animated: false)
        if animated {
            UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navigationController
            })
        } else {
            window.rootViewController = navigationController
        }
    }

    private func presentInternetError(from storyboard: UIStoryboard, on window: UIWindow) {
        let controller = storyboard.instantiateViewController(withIdentifier: "internet")
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.setNavigationBarHidden(true, animated: false)
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: {
            window.rootViewController = navigationController
        })
    }
}
