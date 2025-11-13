import UIKit

final class ChannelsTableCell: UITableViewCell {
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var developer: UILabel!
    @IBOutlet weak var insight: UILabel!
    @IBOutlet weak var streamurl: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnail.image = nil
        name.text = nil
        developer.text = nil
        insight.text = nil
        streamurl.text = nil
    }

    func configure(with channel: Channel) {
        name.text = channel.name
        developer.text = channel.developer
        insight.text = channel.insight
        streamurl.text = channel.streamURL?.absoluteString
    }
}
