import Foundation

/// 実機に入ったアプリの署名情報（embedded.mobileprovision）を読む。
/// Sideloadlyが署名し直すときにApp Groupの名前を書き換えることがあるため、
/// 実際に使えるグループ名をここから探す。
enum ProvisionInfo {
    static let profile: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex)
        else { return nil }
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        return (try? PropertyListSerialization.propertyList(from: plistData, format: nil)) as? [String: Any]
    }()

    static var hasProfile: Bool { profile != nil }

    static var entitlements: [String: Any] {
        profile?["Entitlements"] as? [String: Any] ?? [:]
    }

    /// 署名に含まれているApp Groupの一覧
    static var profileAppGroups: [String] {
        entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }

    static var teamID: String? {
        (profile?["TeamIdentifier"] as? [String])?.first
    }

    static var applicationIdentifier: String? {
        entitlements["application-identifier"] as? String
    }

    /// Info.plistに書き足されたグループ名（署名ツールによっては ALTAppGroups などを追加する）
    static var infoPlistGroups: [String] {
        guard let info = Bundle.main.infoDictionary else { return [] }
        var result: [String] = []
        for (key, value) in info where key.lowercased().contains("group") {
            if let list = value as? [String] {
                result.append(contentsOf: list)
            } else if let single = value as? String, single.hasPrefix("group.") {
                result.append(single)
            }
        }
        return result
    }
}
