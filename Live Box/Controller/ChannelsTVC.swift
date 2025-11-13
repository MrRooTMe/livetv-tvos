import AVKit
import AVFoundation
import Network
import UIKit

final class ChannelsTVC: UITableViewController {
    private var channels: [Channel] = []
    private let api = LiveBoxAPI()
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "LiveBox.NetworkMonitor")

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadChannels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
        startMonitoringNetwork()
        tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
        stopMonitoringNetwork()
    }

    private func loadChannels() {
        guard let activationCode = KeychainStore.shared.activationCode, !activationCode.isEmpty else {
            presentActivationFlow()
            return
        }

        api.fetchChannels(code: activationCode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let channels):
                    self.channels = channels
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentError(message: "Unable to load channels.\n\(error.localizedDescription)")
                }
            }
        }
    }

    private func startMonitoringNetwork() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { path in
            if path.status != .satisfied {
                NSLog("Network connection unavailable")
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func stopMonitoringNetwork() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    private func presentActivationFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let loginController = storyboard.instantiateViewController(withIdentifier: "login")
        let navigationController = UINavigationController(rootViewController: loginController)
        navigationController.setNavigationBarHidden(true, animated: false)
        present(navigationController, animated: true)
    }

    private func presentError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "appCell", for: indexPath) as? ChannelsTableCell
        else {
            return UITableViewCell()
        }

        let channel = channels[indexPath.row]
        cell.configure(with: channel)
        return cell
    }

    @IBAction private func donate() {
        guard let url = URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D9X7Y6LJZPZR8") else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let channel = channels[indexPath.row]

        guard let url = channel.streamURL else {
            presentError(message: "Stream unavailable for \(channel.name).")
            return
        }

        if channel.opensExternally {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            present(playerViewController, animated: true) {
                player.play()
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}
