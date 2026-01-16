# iOS Camera Documentation

## DocCドキュメントのビルド方法

このプロジェクトには DocC フォーマットのドキュメントコメントが含まれています。
Xcode で美しいドキュメントを閲覧するには、以下の手順に従ってください。

## Xcodeでドキュメントを表示する

### 方法1: Quick Help で表示

1. Xcode でコードを開く
2. クラス名や関数名に `Option` キーを押しながらカーソルを合わせる
3. Quick Help ポップアップが表示される
4. 詳細を見るには、ポップアップの右上の「Open in Developer Documentation」をクリック

### 方法2: Developer Documentation ウィンドウ

1. Xcode メニューバーから `Window` > `Developer Documentation` を選択
2. 検索バーでクラス名や関数名を検索
3. プロジェクト内のドキュメントが表示される

### 方法3: DocC Catalog からビルド

Xcode 13 以降では、DocC Catalog を使って静的なドキュメントサイトを生成できます。

#### ビルドコマンド

```bash
# プロジェクトルートで実行
xcodebuild docbuild \
  -scheme iOS_Camera \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath ./DerivedData

# 生成されたドキュメントを開く
open ./DerivedData/Build/Products/Debug-iphonesimulator/iOS_Camera.doccarchive
```

## ドキュメント化されているコンポーネント

### 主要クラス

- **CameraService**: カメラ機能の中核サービス
  - セッション管理
  - デバイス制御
  - 写真撮影

- **CountDownTimer**: カウントダウンタイマー
  - タイマー制御
  - 完了コールバック

- **MonochromeImage**: 画像処理ユーティリティ
  - モノクローム変換

### ビューコンポーネント

- **CustomCameraView**: メインカメラUI
- **CameraView**: UIKit 橋渡しビュー
- **SettingCameraButton**: 設定ボタン
- **ShutterButton**: シャッターボタン
- **OutputImageMirrorButton**: ミラーリングボタン
- **PopupSettingMessageView**: メッセージポップアップ

## DocC コメントの構造

このプロジェクトでは、以下の DocC マークアップを使用しています：

### 基本構造

```swift
/// 簡潔な1行の説明
///
/// より詳細な説明がここに入ります。
/// 複数行にわたって説明できます。
///
/// ## セクション見出し
///
/// セクションの内容
///
/// - Parameter name: パラメータの説明
/// - Returns: 戻り値の説明
/// - Note: 注意事項
/// - Important: 重要な情報
```

### よく使われるセクション

- `## 概要` - コンポーネントの概要
- `## 主な機能` - 提供する機能のリスト
- `## 使用例` - コード例
- `## 動作` - 動作の詳細
- `## 注意事項` - 使用時の注意点

### キャロウト（強調表示）

- `- Note:` - 補足情報
- `- Important:` - 重要な情報
- `- Warning:` - 警告
- `- Tip:` - ヒント
- `- Experiment:` - 実験的機能

## ドキュメントの追加方法

新しいクラスやメソッドを追加する際は、以下のテンプレートを使用してください：

### クラスドキュメント

```swift
/// クラスの簡潔な説明
///
/// より詳細な説明。
///
/// ## 主な機能
///
/// - 機能1
/// - 機能2
///
/// ## 使用例
///
/// ```swift
/// let instance = MyClass()
/// instance.doSomething()
/// ```
class MyClass {
    // ...
}
```

### メソッドドキュメント

```swift
/// メソッドの簡潔な説明
///
/// 詳細な説明。
///
/// - Parameters:
///   - param1: パラメータ1の説明
///   - param2: パラメータ2の説明
/// - Returns: 戻り値の説明
/// - Throws: スローされる可能性のあるエラー
///
/// ## 使用例
///
/// ```swift
/// let result = myMethod(param1: value1, param2: value2)
/// ```
func myMethod(param1: String, param2: Int) -> Bool {
    // ...
}
```

### プロパティドキュメント

```swift
/// プロパティの簡潔な説明
///
/// より詳細な説明。
///
/// - Note: 特記事項があればここに。
var myProperty: String
```

## ベストプラクティス

1. **簡潔で明確に**: 最初の1行は簡潔に要点を伝える
2. **例を示す**: 可能な限りコード例を含める
3. **注意事項を明記**: 重要な情報は `Important` や `Warning` で強調
4. **一貫性を保つ**: プロジェクト全体で同じスタイルを使用
5. **更新を忘れずに**: コード変更時はドキュメントも更新

## 参考リンク

- [Apple DocC Documentation](https://www.swift.org/documentation/docc/)
- [Writing Great Documentation](https://developer.apple.com/videos/play/wwdc2021/10166/)
- [Swift Documentation Markup](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

---

**最終更新**: 2026年1月15日
