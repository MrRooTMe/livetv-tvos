import UIKit

final class FirstTimeScreenViewController: UIViewController {
    @IBOutlet private weak var code: UITextField!

    private let api = LiveBoxAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction private func activatebutton(_ sender: Any) {
        let trimmedCode = code.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedCode.isEmpty else {
            presentAlert(title: "Error", message: "Please enter your Live Box for tvOS activation code")
            return
        }

        api.requestActivation(code: trimmedCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let outcome):
                    if outcome.isValid {
                        KeychainStore.shared.setActivationCode(trimmedCode)
                        self.transitionToMainInterface()
                    } else {
                        self.presentAlert(title: "Error", message: outcome.message)
                    }
                case .failure:
                    self.presentAlert(title: "Error", message: "Network Error")
                }
            }
        }
    }

    private func transitionToMainInterface() {
        guard let storyboard = storyboard else { return }
        let controller = storyboard.instantiateInitialViewController()

        if let window = (UIApplication.shared.delegate as? AppDelegate)?.window {
            UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: {
                window.rootViewController = controller
            })
        }

        dismiss(animated: true, completion: nil)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
