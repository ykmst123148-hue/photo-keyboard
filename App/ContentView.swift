import SwiftUI

/// 確認用の画面：色を選ぶと共有フォルダに保存し、キーボードの背景に反映されるかを確かめる
struct ContentView: View {
    private let swatches: [(name: String, hex: String)] = [
        ("赤", "#E74C3C"),
        ("青", "#3498DB"),
        ("緑", "#27AE60"),
        ("紫", "#8E44AD"),
        ("橙", "#E67E22"),
        ("灰", "#7F8C8D"),
    ]

    @State private var selectedHex: String? = SharedStore.loadColorFromDefaults()
    @State private var saveResult: String = "まだ保存していません"
    @State private var testText: String = ""

    private var containerOK: Bool { SharedStore.containerURL != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("共有フォルダ（App Group）") {
                    Label(containerOK ? "使える" : "使えない",
                          systemImage: containerOK ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(containerOK ? Color.green : Color.red)
                    Text(SharedStore.groupID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("診断（署名の情報）") {
                    diagRow("署名ファイル", ProvisionInfo.hasProfile ? "あり" : "なし")
                    diagRow("チームID", ProvisionInfo.teamID ?? "-")
                    diagRow("アプリID", ProvisionInfo.applicationIdentifier ?? "-")
                    diagRow("署名のグループ", list(ProvisionInfo.profileAppGroups))
                    diagRow("Info.plistのグループ", list(ProvisionInfo.infoPlistGroups))
                    diagRow("使っているグループ", SharedStore.groupID)
                }

                Section("キーボードの背景色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(swatches, id: \.hex) { item in
                            Button {
                                save(item.hex)
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: UIColor(hex: item.hex) ?? .gray))
                                        .frame(height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedHex == item.hex ? Color.primary : .clear, lineWidth: 3)
                                        )
                                    Text(item.name).font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    Text(saveResult)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("ここで打って確かめる") {
                    TextField("タップしてキーボードを切り替える", text: $testText)
                }

                Section("キーボードの追加方法") {
                    Text("設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → 着せ替えキーボード")
                        .font(.footnote)
                }
            }
            .navigationTitle("着せ替えキーボード")
        }
    }

    private func diagRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption.monospaced()).textSelection(.enabled)
        }
    }

    private func list(_ items: [String]) -> String {
        items.isEmpty ? "なし" : items.joined(separator: "\n")
    }

    private func save(_ hex: String) {
        let result = SharedStore.saveColor(hex: hex)
        selectedHex = hex
        saveResult = "保存 \(hex)：設定値 \(result.defaults ? "OK" : "NG") / ファイル \(result.file ? "OK" : "NG")"
    }
}
