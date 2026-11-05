import UIKit

/// 確認用のキーボード：共有フォルダの色を背景にし、読めたかどうかを上部に表示する
final class KeyboardViewController: UIInputViewController {
    private let statusLabel = UILabel()
    private var shiftOn = false
    private var letterButtons: [UIButton] = []

    private let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySharedColor()
    }

    // MARK: 共有フォルダの読み込み

    private func applySharedColor() {
        let fromDefaults = SharedStore.loadColorFromDefaults()
        let fromFile = SharedStore.loadColorFromFile()
        let hex = fromDefaults ?? fromFile

        if let hex, let color = UIColor(hex: hex) {
            view.backgroundColor = color
        } else {
            view.backgroundColor = UIColor.systemGray4
        }

        let d = fromDefaults.map { "OK \($0)" } ?? "NG"
        let f = fromFile.map { "OK \($0.trimmingCharacters(in: .whitespacesAndNewlines))" } ?? "NG"
        let container = SharedStore.containerURL != nil ? "OK" : "NG"
        statusLabel.text = "グループ: \(SharedStore.groupID) 共有: \(container)\n設定値: \(d) / ファイル: \(f)"
    }

    // MARK: レイアウト

    private func buildLayout() {
        statusLabel.font = .systemFont(ofSize: 10)
        statusLabel.numberOfLines = 2
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.6
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        statusLabel.layer.cornerRadius = 4
        statusLabel.clipsToBounds = true

        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 8
        column.translatesAutoresizingMaskIntoConstraints = false
        column.addArrangedSubview(statusLabel)

        for (index, row) in rows.enumerated() {
            let rowStack = makeRow()
            if index == 2 {
                rowStack.addArrangedSubview(makeKey("⇧", width: 1.4, action: #selector(shiftTapped)))
            }
            for letter in row {
                let b = makeKey(letter, action: #selector(letterTapped(_:)))
                letterButtons.append(b)
                rowStack.addArrangedSubview(b)
            }
            if index == 2 {
                rowStack.addArrangedSubview(makeKey("⌫", width: 1.4, action: #selector(deleteTapped)))
            }
            column.addArrangedSubview(index == 0 ? rowStack : centered(rowStack))
        }

        let bottom = makeRow()
        if needsInputModeSwitchKey {
            let globe = makeKey("🌐", width: 1.4, action: nil)
            globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            bottom.addArrangedSubview(globe)
        }
        bottom.addArrangedSubview(makeKey("space", width: nil, action: #selector(spaceTapped)))
        bottom.addArrangedSubview(makeKey("return", width: 2, action: #selector(returnTapped)))
        column.addArrangedSubview(bottom)

        view.addSubview(column)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            column.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            column.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            column.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            statusLabel.heightAnchor.constraint(equalToConstant: 28),
        ])

        // キー幅の制約は、全部のキーが画面に載ったあとで有効にする
        if let unit = pendingWidths.first?.button {
            for item in pendingWidths.dropFirst() {
                item.button.widthAnchor.constraint(equalTo: unit.widthAnchor, multiplier: item.width).isActive = true
            }
        }

        let height = view.heightAnchor.constraint(equalToConstant: 270)
        height.priority = .defaultHigh
        height.isActive = true
    }

    private func makeRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 6
        s.distribution = .fill
        return s
    }

    /// 2段目と3段目は幅が足りないので、中央寄せにする
    private func centered(_ row: UIStackView) -> UIView {
        let wrapper = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: wrapper.topAnchor),
            row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            row.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
        ])
        return wrapper
    }

    /// 1文字キーの幅を基準にした倍率。最初に登録したキー（q）が基準になる
    private var pendingWidths: [(button: UIButton, width: CGFloat)] = []

    private func makeKey(_ title: String, width: CGFloat? = 1, action: Selector?) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: title.count == 1 ? 22 : 16)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        b.layer.cornerRadius = 5
        if let action { b.addTarget(self, action: action, for: .touchUpInside) }
        if let width { pendingWidths.append((b, width)) }
        return b
    }

    // MARK: キー操作

    @objc private func letterTapped(_ sender: UIButton) {
        guard let t = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(t)
        if shiftOn { setShift(false) }
    }

    @objc private func shiftTapped() { setShift(!shiftOn) }

    private func setShift(_ on: Bool) {
        shiftOn = on
        for b in letterButtons {
            guard let t = b.title(for: .normal) else { continue }
            b.setTitle(on ? t.uppercased() : t.lowercased(), for: .normal)
        }
    }

    @objc private func deleteTapped() { textDocumentProxy.deleteBackward() }
    @objc private func spaceTapped() { textDocumentProxy.insertText(" ") }
    @objc private func returnTapped() { textDocumentProxy.insertText("\n") }
}
