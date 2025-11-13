import Foundation

struct Channel: Decodable {
    let name: String
    let insight: String?
    let developer: String?
    let versioning: String?
    let thumbnailURL: URL?
    let iconURL: URL?
    let about: String?
    let lastUpdated: String?
    let category: String?
    let streamURL: URL?
    let itmsLink: URL?
    let opensExternally: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case insight
        case developer
        case versioning
        case thumbnail
        case icon
        case about
        case lastupdated
        case category
        case streamurl
        case itmslink
        case webcheck
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Channel"
        insight = container.decodeIfPresent(String.self, forKey: .insight)
        developer = container.decodeIfPresent(String.self, forKey: .developer)
        versioning = container.decodeIfPresent(String.self, forKey: .versioning)
        if let thumbnailString = container.decodeIfPresent(String.self, forKey: .thumbnail) {
            thumbnailURL = URL(string: thumbnailString)
        } else {
            thumbnailURL = nil
        }
        if let iconString = container.decodeIfPresent(String.self, forKey: .icon) {
            iconURL = URL(string: iconString)
        } else {
            iconURL = nil
        }
        about = container.decodeIfPresent(String.self, forKey: .about)
        lastUpdated = container.decodeIfPresent(String.self, forKey: .lastupdated)
        category = container.decodeIfPresent(String.self, forKey: .category)
        if let streamString = container.decodeIfPresent(String.self, forKey: .streamurl) {
            streamURL = URL(string: streamString)
        } else {
            streamURL = nil
        }
        if let linkString = container.decodeIfPresent(String.self, forKey: .itmslink) {
            itmsLink = URL(string: linkString)
        } else {
            itmsLink = nil
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .webcheck) {
            opensExternally = boolValue
        } else if let stringValue = container.decodeIfPresent(String.self, forKey: .webcheck) {
            let normalized = stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            opensExternally = normalized == "true" || normalized == "1"
        } else {
            opensExternally = false
        }
    }
}
