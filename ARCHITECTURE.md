# iOS Camera App - アーキテクチャドキュメント

## 📋 目次

1. [概要](#概要)
2. [アーキテクチャパターン](#アーキテクチャパターン)
3. [レイヤー構成](#レイヤー構成)
4. [コンポーネント詳細](#コンポーネント詳細)
5. [データフロー](#データフロー)
6. [設計判断](#設計判断)
7. [技術的な詳細](#技術的な詳細)
8. [拡張ポイント](#拡張ポイント)

---

## 概要

このアプリケーションは、SwiftUI と AVFoundation を組み合わせた MVVM 風のアーキテクチャを採用しています。UIKit の強力なカメラ機能を SwiftUI の宣言的な UI で活用するため、`UIViewControllerRepresentable` を用いた橋渡しパターンを採用しています。

### 設計の核となる原則

- **関心の分離**: UI、ビジネスロジック、カメラ制御を明確に分離
- **単一責任の原則**: 各コンポーネントは1つの明確な責任を持つ
- **宣言的UI**: SwiftUI の特性を活かした状態駆動型の UI
- **非同期処理**: カメラセッションは別スレッドで処理し、UI をブロックしない

---

## アーキテクチャパターン

### 全体構成図

```
┌──────────────────────────────────────────────────────────┐
│                     iOS_CameraApp                        │
│                   (App Entry Point)                      │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│              CustomCameraView (SwiftUI)                  │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Top Controls (HStack)                             │  │
│  │  - Flash Toggle                                    │  │
│  │  - Camera Toggle                                   │  │
│  │  - Focus Mode Toggle                               │  │
│  │  - Mirror Toggle                                   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │            CameraView (Preview)                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Bottom Controls                                   │  │
│  │  - Shutter Button                                  │  │
│  │  - Countdown Display                               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Toast Message (Optional)                          │  │
│  └────────────────────────────────────────────────────┘  │
└────────┬──────────────────────────┬──────────────────────┘
         │                          │
         ▼                          ▼
┌────────────────────┐    ┌────────────────────┐
│    CameraView      │    │  CountDownTimer    │
│(UIKit Bridging)    │    │  (Timer Model)     │
└────────┬───────────┘    └─────────┬──────────┘
         │                          │
         │                          │
         ▼                          │
┌────────────────────┐              │
│  CameraService     │◄─────────────┘
│ (AVFoundation)     │
└────────────────────┘
         │
         ▼
┌────────────────────┐
│  AVCaptureSession  │
│  AVCaptureDevice   │
│  AVCapturePhoto    │
│  Output            │
└────────────────────┘
```

### レイヤー分離

このアーキテクチャは以下の3つの主要レイヤーに分かれています：

1. **View Layer** (SwiftUI)
   - ユーザーインタラクション
   - UI の表示と更新
   - 状態の監視

2. **Service Layer** (Business Logic)
   - カメラ制御ロジック
   - タイマー管理
   - 写真撮影処理

3. **Framework Layer** (AVFoundation)
   - カメラハードウェアへのアクセス
   - キャプチャセッション管理

---

## レイヤー構成

### 1. View Layer (SwiftUI)

#### CustomCameraView.swift
- **役割**: メインのカメラ UI コンポーネント
- **責任**:
  - ユーザーインタラクションの受付
  - カメラ設定ボタンの表示
  - シャッターボタンとカウントダウン表示
  - トーストメッセージの表示
- **状態管理**:
  - `@StateObject` で `CameraService` と `CountDownTimer` を保持
  - `@State` でローカル UI 状態（フラッシュ、カメラ位置など）を管理

#### CameraView.swift
- **役割**: UIKit と SwiftUI の橋渡し
- **責任**:
  - `UIViewControllerRepresentable` の実装
  - AVCaptureSession のプレビューレイヤー表示
  - 写真撮影時のコールバック処理
- **パターン**: Coordinator パターン

#### OutputPhotoView.swift
- **役割**: 撮影後の写真表示
- **責任**:
  - キャプチャした写真のプレビュー
  - 保存またはリトライの選択肢提供

### 2. Service Layer

#### CameraService.swift
- **役割**: カメラ機能の中核サービス
- **責任**:
  - AVCaptureSession のライフサイクル管理
  - カメラ権限の確認と要求
  - デバイス設定（フラッシュ、フォーカス、カメラ位置）
  - 写真撮影の実行
  - エラーハンドリング
- **プロトコル**: `ObservableObject`
- **主要プロパティ**:
  - `session: AVCaptureSession`
  - `currentCamera: AVCaptureDevice.Position`
  - `isFlashOn: Bool`
  - `isAutoContinuousFocus: Bool`

#### CountDownTimer.swift
- **役割**: カウントダウンタイマーの管理
- **責任**:
  - タイマーの開始・停止
  - カウント値の更新
  - 完了時のコールバック実行
- **プロトコル**: `ObservableObject`
- **主要プロパティ**:
  - `count: Int` - 現在のカウント値
  - `isRunning: Bool` - タイマーの実行状態

### 3. Utility Layer

#### MonochromeImage.swift
- **役割**: 画像処理ユーティリティ
- **責任**:
  - CIFilter を使用したモノクローム変換
  - 画像処理のヘルパー関数
- **現状**: 実装済みだが未使用（将来の拡張用）

---

## コンポーネント詳細

### CameraService

```swift
class CameraService: NSObject, ObservableObject {
    // セッション管理
    let session = AVCaptureSession()
    
    // 状態
    @Published var isAuthorized = false
    @Published var currentCamera: AVCaptureDevice.Position = .back
    
    // 設定
    var isFlashOn = false
    var isAutoContinuousFocus = false
    var isMirrored = false
    
    // ライフサイクル
    func checkAuthorization()
    func startSession()
    func stopSession()
    
    // デバイス制御
    func toggleFlash()
    func switchCamera()
    func toggleFocusMode()
    func toggleMirror()
    
    // 撮影
    func capturePhoto(completion: @escaping (Data?) -> Void)
}
```

**設計上の考慮事項**:
- `ObservableObject` により状態変更を自動的に UI に反映
- AVFoundation API は Background Queue で実行
- エラーハンドリングは `print()` で簡易的に実装（本番環境では改善が必要）

### CountDownTimer

```swift
class CountDownTimer: ObservableObject {
    @Published var count: Int = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    
    func startCountdown(from: Int, completion: @escaping () -> Void)
    func stopCountdown()
}
```

**設計上の考慮事項**:
- `Timer` を使用した1秒間隔のカウントダウン
- 完了時に自動的にコールバックを実行
- UI バインディングのため `@Published` プロパティを使用

### CameraView (Coordinator パターン)

```swift
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraService: CameraService
    var didFinishCapturing: (Data?) -> Void
    
    // UIKit -> SwiftUI 橋渡し
    func makeUIViewController(context: Context) -> UIViewController
    func updateUIViewController(...)
    
    // Coordinator (Delegate 処理)
    func makeCoordinator() -> Coordinator
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        func photoOutput(_ output: AVCapturePhotoOutput, 
                        didFinishProcessingPhoto photo: AVCapturePhoto, 
                        error: Error?)
    }
}
```

**設計上の考慮事項**:
- SwiftUI で UIKit のビューコントローラーをホスト
- Coordinator が AVCapturePhotoCaptureDelegate を実装
- クロージャーでキャプチャ結果を親ビューに伝達

---

## データフロー

### 1. アプリ起動フロー

```
アプリ起動
    │
    ├─> iOS_CameraApp.swift (@main)
    │       │
    │       └─> CustomCameraView を表示
    │               │
    │               ├─> CameraService を初期化 (@StateObject)
    │               ├─> CountDownTimer を初期化 (@StateObject)
    │               └─> .onAppear でカメラ権限確認
    │                       │
    │                       └─> CameraService.checkAuthorization()
    │                               │
    │                               ├─> 権限あり -> startSession()
    │                               └─> 権限なし -> 権限リクエスト
```

### 2. 撮影フロー

```
ユーザーがシャッターボタンをタップ
    │
    ├─> タイマー実行中か確認
    │   ├─> 実行中 -> 処理中断
    │   └─> 未実行 -> カウントダウン開始
    │
    ├─> CountDownTimer.startCountdown(from: 3)
    │       │
    │       ├─> count が @Published で更新 (3 -> 2 -> 1 -> 0)
    │       └─> UI に自動反映（カウント表示）
    │
    ├─> カウントダウン完了（completion クロージャー）
    │       │
    │       └─> CameraService.capturePhoto()
    │               │
    │               ├─> AVCapturePhotoOutput.capturePhoto()
    │               └─> Coordinator がデリゲートメソッドで受け取り
    │                       │
    │                       └─> didFinishCapturing クロージャー実行
    │                               │
    │                               └─> outputPhoto に画像データ保存
    │
    └─> outputPhoto != nil で OutputPhotoView を表示
```

### 3. 設定変更フロー

```
ユーザーが設定ボタンをタップ (例: フラッシュ)
    │
    ├─> CustomCameraView の @State プロパティを更新
    │       │
    │       └─> isFlashOn.toggle()
    │
    ├─> CameraService のメソッドを呼び出し
    │       │
    │       └─> CameraService.toggleFlash()
    │               │
    │               ├─> デバイスをロック (lockForConfiguration)
    │               ├─> torchMode を変更
    │               └─> デバイスをアンロック
    │
    └─> トーストメッセージを表示
            │
            ├─> showMessage = true
            ├─> 2秒後に自動非表示
            └─> UI に反映
```

---

## 設計判断

### なぜ MVVM 風なのか？

このアプリは厳密な MVVM ではなく、「MVVM 風」としています：

**MVVM の要素**:
- ✅ View (CustomCameraView, CameraView)
- ✅ Model (暗黙的: AVFoundation のデータ)
- ⚠️ ViewModel (CameraService が部分的に担当)

**純粋な MVVM との違い**:
- `CameraService` が ViewModel と Service の両方の役割を持つ
- ビジネスロジックとフレームワーク層が密結合

**この設計を選んだ理由**:
1. **シンプルさ**: 小規模アプリなので過度な抽象化を避けた
2. **AVFoundation との親和性**: カメラ制御は AVFoundation と密接に関連
3. **SwiftUI との統合**: `ObservableObject` で状態管理がシンプルに

### UIViewControllerRepresentable の採用理由

**選択肢**:
1. ❌ SwiftUI のみ: カメラプレビュー機能がない
2. ❌ UIKit のみ: SwiftUI の宣言的 UI を活用できない
3. ✅ **Hybrid (UIViewControllerRepresentable)**: 両者の利点を活用

**利点**:
- AVFoundation の強力なカメラ機能を活用
- SwiftUI の宣言的な UI とデータバインディング
- 段階的な SwiftUI 移行が可能

**トレードオフ**:
- Coordinator パターンの学習コスト
- UIKit と SwiftUI の境界でのデータ受け渡し

### ObservableObject の活用

**なぜ ObservableObject を使うのか**:
- SwiftUI との自動的なデータバインディング
- `@Published` による変更通知の簡潔さ
- 状態管理の一元化

**代替案**:
- `@State` のみ: ロジックが View に集中してしまう
- Combine フレームワーク: オーバーエンジニアリング
- Actor: カメラ API が actor-safe でない

---

## 技術的な詳細

### スレッド管理

#### AVFoundation の非同期処理

```swift
// セッション開始は Background Queue で実行
DispatchQueue.global(qos: .userInitiated).async {
    session.startRunning()
}

// UI 更新は Main Queue で実行
DispatchQueue.main.async {
    // UI 更新
}
```

**理由**:
- `startRunning()` は重い処理なので UI スレッドをブロックしない
- AVCaptureSession の推奨ベストプラクティス

#### Timer の実行コンテキスト

```swift
// Timer は Main RunLoop で実行
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    // Main Thread で実行される
}
```

### メモリ管理

#### Weak/Strong 参照

```swift
class Coordinator: NSObject {
    var parent: CameraView  // Strong 参照: CameraView は構造体なので問題なし
    var completion: (Data?) -> Void  // クロージャーのキャプチャに注意
}
```

**注意点**:
- Coordinator は CameraView の内部クラスなので、循環参照の可能性がある
- クロージャーでの `self` キャプチャに注意が必要

#### Session のライフサイクル

```swift
// View の onDisappear でセッション停止
.onDisappear {
    cameraService.stopSession()
}
```

**理由**:
- バッテリー消費を抑える
- カメラリソースを解放

### 権限管理

#### カメラ権限の確認フロー

```swift
func checkAuthorization() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        isAuthorized = true
        startSession()
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted { self.startSession() }
            }
        }
    case .denied, .restricted:
        isAuthorized = false
    @unknown default:
        isAuthorized = false
    }
}
```

**ベストプラクティス**:
- `notDetermined` 状態でのみ権限リクエスト
- `denied` 時はユーザーに設定アプリへの誘導が必要（未実装）

---

## 拡張ポイント

### 現在のアーキテクチャで追加しやすい機能

#### 1. 画像フィルタ機能

```swift
// MonochromeImage.swift が既に存在
// CustomCameraView にフィルター選択 UI を追加
// OutputPhotoView でフィルター適用
```

**実装難易度**: 低
**必要な変更箇所**: CustomCameraView, OutputPhotoView

#### 2. ビデオ撮影機能

```swift
// CameraService に AVCaptureMovieFileOutput を追加
// 録画開始/停止メソッドを実装
```

**実装難易度**: 中
**必要な変更箇所**: CameraService, CustomCameraView

#### 3. Portrait Effects Matte

```swift
// CameraService の capturePhoto で深度データを有効化
// 既にコメントアウトされたコードが存在
```

**実装難易度**: 中
**必要な変更箇所**: CameraService

#### 4. フォトライブラリへの保存

```swift
// PhotosKit を使用
// OutputPhotoView に保存ボタンを追加
```

**実装難易度**: 低
**必要な変更箇所**: OutputPhotoView

### アーキテクチャ改善の余地

#### 1. MVVM の明確化

**現状の問題**:
- CameraService が Service と ViewModel の両方の役割を持つ

**改善案**:
```swift
// ViewModel を分離
class CameraViewModel: ObservableObject {
    private let cameraService: CameraService
    @Published var isFlashOn = false
    @Published var currentCamera: AVCaptureDevice.Position = .back
    
    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setFlash(isFlashOn)
    }
}

// Service は純粋なカメラ制御に専念
class CameraService {
    func setFlash(_ on: Bool) { /* ... */ }
    func capturePhoto(completion: @escaping (Result<Data, Error>) -> Void)
}
```

**利点**:
- テストしやすい
- ビジネスロジックと AVFoundation を分離
- エラーハンドリングの改善

**トレードオフ**:
- コード量が増加
- 小規模アプリには過剰

#### 2. エラーハンドリングの改善

**現状の問題**:
- エラーは `print()` のみ
- ユーザーにエラーを通知していない

**改善案**:
```swift
enum CameraError: Error, LocalizedError {
    case unauthorized
    case sessionConfigurationFailed
    case captureFailure(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "カメラへのアクセスが拒否されました"
        // ...
        }
    }
}

class CameraService: ObservableObject {
    @Published var error: CameraError?
    
    func capturePhoto(completion: @escaping (Result<Data, CameraError>) -> Void)
}
```

**利点**:
- ユーザーフレンドリーなエラーメッセージ
- デバッグしやすい
- リトライロジックの実装が可能

#### 3. Dependency Injection

**現状の問題**:
- CameraService が直接 AVFoundation に依存
- テストが困難

**改善案**:
```swift
protocol CameraServiceProtocol {
    func capturePhoto(completion: @escaping (Data?) -> Void)
    func toggleFlash()
}

class CameraService: CameraServiceProtocol {
    // 実装
}

class MockCameraService: CameraServiceProtocol {
    // テスト用モック
}

struct CustomCameraView: View {
    @StateObject var cameraService: any CameraServiceProtocol
}
```

**利点**:
- ユニットテストが可能
- プレビューでのモックデータ使用
- 柔軟な実装の差し替え

**トレードオフ**:
- プロトコルとモックの管理コスト
- `ObservableObject` との併用が複雑

#### 4. Async/Await への移行

**現状の問題**:
- コールバックベースの非同期処理
- ネストが深くなりやすい

**改善案**:
```swift
class CameraService: ObservableObject {
    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            capturePhoto { data in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: CameraError.captureFailure)
                }
            }
        }
    }
}

// 使用側
Button("撮影") {
    Task {
        do {
            let photo = try await cameraService.capturePhoto()
            // 処理
        } catch {
            // エラー処理
        }
    }
}
```

**利点**:
- コードの可読性向上
- エラーハンドリングが簡潔
- Swift の現代的なベストプラクティス

---

## 参考資料

### Apple 公式ドキュメント

- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### 設計パターン

- MVVM (Model-View-ViewModel)
- Coordinator Pattern
- Dependency Injection
- Repository Pattern (将来の拡張用)

---

## まとめ

このアプリケーションは、SwiftUI の宣言的 UI と AVFoundation の強力なカメラ機能を組み合わせた実用的なアーキテクチャを採用しています。

**強み**:
- ✅ 明確な責任分離
- ✅ SwiftUI との親和性
- ✅ 拡張しやすい構造
- ✅ 学習しやすいシンプルさ

**改善の余地**:
- ⚠️ エラーハンドリングの強化
- ⚠️ テストコードの追加
- ⚠️ MVVM の明確化
- ⚠️ Async/Await の採用

小規模なカメラアプリとしては十分な設計ですが、将来的な機能拡張やチーム開発を考慮すると、上記の改善点に取り組むことでより堅牢なアーキテクチャになります。

---

**最終更新日**: 2026年1月15日
