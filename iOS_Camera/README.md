# iOS Camera App

AVFoundation と SwiftUI を使用したカスタムカメラアプリケーションです。リアルタイムプレビュー、各種カメラ設定、カウントダウン撮影機能を提供します。

## 📱 主な機能

### カメラ機能
- **リアルタイムプレビュー**: AVFoundation を使用したカメラプレビュー表示
- **前面/背面カメラの切り替え**: フロントカメラとリアカメラの切り替え
- **フラッシュ制御**: オン/オフの切り替え
- **フォーカスモード切り替え**: オートフォーカス / 連続オートフォーカス
- **出力画像の左右反転設定**: 撮影画像のミラーリング制御

### 撮影機能
- **3秒カウントダウン撮影**: 撮影前に3秒間のカウントダウン
- **視覚的フィードバック**: カウントダウン中の UI 表示

### 画像処理（将来対応予定）
- モノクローム画像変換（`MonochromeImage.swift` に実装済み）
- Portrait Effects Matte 対応（コメントアウト済み）

## 🏗️ アーキテクチャ

このアプリは、SwiftUI と AVFoundation を組み合わせた MVVM 風のアーキテクチャを採用しています。

```
┌─────────────────────────────────────────┐
│         CustomCameraView (UI)           │
│  - カメラ設定ボタン                      │
│  - シャッターボタン                      │
│  - カウントダウン表示                     │
└────────────┬────────────────────────────┘
             │
             ├─────────────────────────────┐
             │                             │
      ┌──────▼──────┐            ┌────────▼────────┐
      │ CameraView  │            │ CountDownTimer  │
      │ (UIKit橋渡し)│            │ (タイマー管理)   │
      └──────┬──────┘            └─────────────────┘
             │
      ┌──────▼──────┐
      │CameraService│
      │(カメラ制御)  │
      └─────────────┘
```

### コンポーネント

#### View Layer (SwiftUI)
- **`CustomCameraView`**: メインのカメラUI
  - カメラ設定ボタン群（フラッシュ、カメラ切り替え、フォーカス、ミラーリング）
  - シャッターボタンとカウントダウン表示
  - 設定変更時のポップアップメッセージ

- **`CameraView`**: UIKit と SwiftUI の橋渡し
  - `UIViewControllerRepresentable` を使用
  - AVCaptureSession のプレビューを SwiftUI に統合
  - Coordinator パターンで写真撮影デリゲートを処理

#### Service Layer
- **`CameraService`**: カメラ機能の中核
  - AVCaptureSession の管理
  - カメラ権限の確認と要求
  - デバイス設定（フラッシュ、フォーカス、カメラ位置）
  - 写真撮影処理

#### Model / Utility Layer
- **`CountDownTimer`**: タイマー機能
  - ObservableObject として状態を管理
  - カウントダウン完了時のコールバック

- **`MonochromeImage`**: 画像処理ユーティリティ
  - CIFilter を使用したモノクローム変換

## 📂 プロジェクト構成

```
iOS_Camera/
├── iOS_CameraApp.swift          # アプリエントリーポイント
├── Views/
│   ├── CustomCameraView.swift   # メインカメラUI
│   └── CameraView.swift         # UIKit橋渡しビュー
├── Services/
│   └── CameraService.swift      # カメラ制御サービス
├── Models/
│   └── CountDownTimer.swift     # タイマーモデル
└── Utilities/
    └── MonochromeImage.swift    # 画像処理ユーティリティ
```

## 🚀 セットアップ

### 必要要件
- **Xcode**: 15.0 以上
- **iOS**: 14.0 以上
- **Swift**: 5.9 以上

### インストール手順

1. **リポジトリをクローン**
   ```bash
   git clone <your-repository-url>
   cd iOS_Camera
   ```

2. **Xcode でプロジェクトを開く**
   ```bash
   open iOS_Camera.xcodeproj
   ```

3. **Info.plist の設定確認**
   
   カメラ使用には以下のキーが必要です：
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>写真を撮影するためにカメラを使用します</string>
   ```

4. **実機またはシミュレーターで実行**
   
   ⚠️ **注意**: カメラ機能は実機でのみ動作します。シミュレーターでは権限エラーが発生します。

## 🎮 使い方

### 基本操作

1. **アプリ起動**: 初回起動時にカメラアクセス権限を許可
2. **プレビュー確認**: リアルタイムでカメラ映像が表示されます
3. **設定調整**: 画面上部のボタンで各種設定を変更
4. **撮影**: 下部の⚪️ボタンをタップ
5. **カウントダウン**: 3秒のカウントダウン後に自動撮影

### カメラ設定ボタン

| アイコン | 機能 | 説明 |
|---------|------|------|
| 🔦 | フラッシュ | オン/オフ切り替え |
| 🔄 | カメラ切り替え | 前面/背面カメラの切り替え |
| 📐 | フォーカスモード | オートフォーカス/連続オートフォーカス |
| 🖼️ | ミラーリング | 出力画像の左右反転 |

## 🧪 テスト

現在、テストコードは未実装です。将来的には以下のテストを追加予定：

- CameraService の単体テスト
- CountDownTimer のタイマー動作テスト
- MonochromeImage の画像変換テスト

## 🔮 将来の拡張予定

### 実装予定の機能
- [ ] Portrait Effects Matte 対応（深度データを使用したポートレート効果）


### コード改善
- [ ] MVVM アーキテクチャの明確化
- [ ] エラーハンドリングの強化
- [ ] 単体テストの追加
- [ ] DocC ドキュメントの追加

## 📝 技術スタック

- **UI Framework**: SwiftUI
- **Camera Framework**: AVFoundation
- **Image Processing**: Core Image (CIFilter)
- **Concurrency**: DispatchQueue, Timer
- **Architecture**: MVVM風

## 🔧 主要な実装ポイント

### UIViewControllerRepresentable
SwiftUI で UIKit のカメラプレビューを表示するため、`CameraView` で `UIViewControllerRepresentable` を使用しています。

### Coordinator パターン
AVCapturePhotoCaptureDelegate の処理を SwiftUI に橋渡しするため、Coordinator を実装しています。

### ObservableObject
`CountDownTimer` は `@ObservableObject` として実装され、タイマーの状態変更が自動的に UI に反映されます。

### 非同期処理
カメラセッションの開始は Background Queue で実行され、UI のブロックを防ぎます。

## ⚠️ 既知の問題

- シミュレーターではカメラが利用できないため、実機でのテストが必須
- Portrait Effects Matte 機能はコメントアウトされており、未実装

## 📄 ライセンス

このプロジェクトのライセンスについては、プロジェクト所有者にお問い合わせください。

## 👤 作成者

Created by hiroto30 (2024/03/16)

---

**Note**: このプロジェクトは学習・実験目的で作成されています。本番環境での使用には追加のエラーハンドリングやセキュリティ対策が必要です。
