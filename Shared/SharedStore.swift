import Foundation
import UIKit

/// 本体アプリとキーボードの間で設定を受け渡す場所（App Group）
enum SharedStore {
    static let groupID = "group.com.kazphotokbd.shared"
    static let colorKey = "keyboardColorHex"
    static let colorFileName = "color.txt"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }

    // MARK: 書き込み（本体アプリ側だけが使う）

    /// UserDefaultsとファイルの両方に保存し、それぞれ成功したかを返す
    static func saveColor(hex: String) -> (defaults: Bool, file: Bool) {
        var defaultsOK = false
        if let d = defaults {
            d.set(hex, forKey: colorKey)
            defaultsOK = d.string(forKey: colorKey) == hex
        }
        var fileOK = false
        if let url = containerURL?.appendingPathComponent(colorFileName) {
            do {
                try hex.write(to: url, atomically: true, encoding: .utf8)
                fileOK = true
            } catch {
                fileOK = false
            }
        }
        return (defaultsOK, fileOK)
    }

    // MARK: 読み込み（キーボード側も使う）

    static func loadColorFromDefaults() -> String? {
        defaults?.string(forKey: colorKey)
    }

    static func loadColorFromFile() -> String? {
        guard let url = containerURL?.appendingPathComponent(colorFileName) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

extension UIColor {
    /// "#RRGGBB" 形式から色を作る。形式が違えば nil
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }
}
