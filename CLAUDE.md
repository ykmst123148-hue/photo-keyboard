# 着せ替えキーボード（photo-keyboard）

- 自分のiPhoneだけで使う、写真を背景にできる英字QWERTYキーボード
- 構成：本体アプリ（写真選択と調整）＋キーボード拡張
- Macはない。ビルドはGitHub Actions（macOS）、iPhoneへの導入はWindowsのSideloadly（無料Apple ID）
- 画像の加工は本体アプリで済ませ、キーボードは共有フォルダ（App Group）を読むだけにする
- キーボードのフルアクセス（RequestsOpenAccess）は使わない
- 日本語入力・かな漢字変換・App Store公開は作らない
- 作業が終わったら、Actionsの結果（成功/失敗とログの要点）とシミュレータのスクショを見せる
- 確かめられなかったことは「未確認」と書く
- 頼まれていない場所は変更しない
