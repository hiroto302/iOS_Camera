# ``iOS_Camera``

AVFoundation と SwiftUI を使用したカスタムカメラアプリケーション

## 概要

iOS_Camera は、AVFoundation フレームワークを使用してカメラ機能を提供する iOS アプリケーションです。
SwiftUI の宣言的 UI と UIKit の強力なカメラ機能を組み合わせ、リアルタイムプレビュー、
各種カメラ設定、カウントダウン撮影機能を実装しています。

## トピック

### カメラ制御

カメラセッションとデバイス制御を管理するコンポーネント。

- ``CameraService``
- ``CameraView``

### ユーザーインターフェース

SwiftUI で構築されたカメラ UI コンポーネント。

- ``CustomCameraView``
- ``SettingCameraButton``
- ``ShutterButton``
- ``OutputImageMirrorButton``
- ``PopupSettingMessageView``

### ユーティリティ

タイマーや画像処理などの補助機能。

- ``CountDownTimer``
- ``MonochromeImage``

## はじめに

### 必要要件

- iOS 14.0 以上
- Xcode 15.0 以上
- カメラ使用権限 (`NSCameraUsageDescription`)

### 基本的な使い方

カメラビューを表示する最もシンプルな方法:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        CustomCameraView()
    }
}
```

### カメラサービスの初期化

カメラサービスを手動で初期化して使用する場合:

```swift
let cameraService = CameraService()

cameraService.start(delegate: self) { error in
    if let error = error {
        print("カメラ起動エラー: \(error)")
    } else {
        print("カメラ起動成功")
    }
}
```

## 主な機能

### カメラ機能

- **リアルタイムプレビュー**: AVFoundation を使用したカメラプレビュー
- **カメラ切り替え**: 前面カメラと背面カメラの切り替え
- **フラッシュ制御**: オン/オフの切り替え
- **フォーカスモード**: オートフォーカス/連続オートフォーカス
- **ミラーリング**: 出力画像の左右反転

### 撮影機能

- **カウントダウン撮影**: 3秒のカウントダウン後に自動撮影
- **視覚的フィードバック**: カウントダウン中の UI 表示

### 画像処理（将来対応予定）

- モノクローム画像変換
- Portrait Effects Matte

## アーキテクチャ

このアプリは MVVM 風のアーキテクチャを採用しています:

- **View Layer**: SwiftUI によるUI構築
- **Service Layer**: カメラ制御とビジネスロジック
- **Utility Layer**: 汎用的なヘルパー機能

詳細は ``CameraService`` と ``CustomCameraView`` のドキュメントを参照してください。

## 関連情報

- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
