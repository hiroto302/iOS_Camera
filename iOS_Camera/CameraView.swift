import SwiftUI
import AVFoundation

/// SwiftUI でカメラプレビューを表示するためのビューコンポーネント
///
/// `UIViewControllerRepresentable` を使用して、UIKit の `UIViewController` を SwiftUI に統合します。
/// AVFoundation のカメラプレビューレイヤーを SwiftUI ビューとして表示するための橋渡しを行います。
///
/// ## 主な役割
///
/// - UIKit の `UIViewController` を SwiftUI で表示
/// - カメラプレビューレイヤーの配置
/// - 写真撮影結果を SwiftUI に伝達
///
/// ## 使用例
///
/// ```swift
/// CameraView(cameraService: cameraService) { result in
///     switch result {
///     case .success(let photo):
///         // 撮影成功時の処理
///     case .failure(let error):
///         // エラー時の処理
///     }
/// }
/// ```
///
/// - Note: Coordinator パターンを使用して、AVCapturePhotoCaptureDelegate のイベントを SwiftUI に伝達します。
struct CameraView: UIViewControllerRepresentable {

    /// 使用する UIViewController の型
    ///
    /// 標準的な `UIViewController` を使用します。
    typealias UIViewControllerType = UIViewController
    
    /// カメラサービスのインスタンス
    ///
    /// カメラセッションとプレビューレイヤーを管理します。
    let cameraService: CameraService
    
    /// 写真撮影完了時のコールバック
    ///
    /// 撮影結果を `Result` 型で受け取ります。
    /// - 成功時: `AVCapturePhoto` オブジェクト
    /// - 失敗時: `Error` オブジェクト
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

    /// UIViewController を生成します
    ///
    /// SwiftUI がこのビューを初めて表示するときに呼ばれます。
    ///
    /// - Parameter context: SwiftUI が提供するコンテキスト（Coordinator を含む）
    /// - Returns: カメラプレビューを表示する `UIViewController`
    ///
    /// ## 実行される処理
    ///
    /// 1. カメラサービスを開始
    /// 2. 黒背景の UIViewController を作成
    /// 3. プレビューレイヤーをサブレイヤーとして追加
    /// 4. プレビューレイヤーのフレームを設定
    ///
    /// - Note: カメラの初期化エラーは `didFinishProcessingPhoto` コールバックで通知されます。
    func makeUIViewController(context: Context) -> UIViewController {
        // CameraServiceを開始
        cameraService.start(delegate: context.coordinator) { err in
            if let err = err {
                didFinishProcessingPhoto(.failure(err))
                return
            }
        }

        // UIViewControllerの作成
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        // プレビューレイヤーをUIViewControllerのサブレイヤーとして追加
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        // カメラのプレビューレイヤーのフレームをviewControllerの境界に設定
        cameraService.previewLayer.frame = viewController.view.bounds

        return viewController
    }

    /// Coordinator インスタンスを生成します
    ///
    /// SwiftUI が `makeUIViewController` を呼ぶ前に自動的に呼ばれます。
    /// Coordinator は UIKit のデリゲートメソッドを SwiftUI に橋渡しする役割を持ちます。
    ///
    /// - Returns: 新しい `Coordinator` インスタンス
    ///
    /// - Note: Coordinator パターンは SwiftUI と UIKit を統合する際の標準的な手法です。
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }

    /// UIViewController を更新します
    ///
    /// SwiftUI の状態が変更され、ビューの更新が必要になったときに呼ばれます。
    /// このビューでは特に更新処理を行いません。
    ///
    /// - Parameters:
    ///   - uiViewController: 更新対象の UIViewController
    ///   - context: SwiftUI が提供するコンテキスト
    ///
    /// - Note: カメラプレビューは動的に更新されるため、手動更新は不要です。
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }


    /// AVCapturePhoto のキャプチャ処理を担当する Coordinator
    ///
    /// UIKit の `AVCapturePhotoCaptureDelegate` を実装し、
    /// 写真撮影の完了イベントを SwiftUI に伝達します。
    ///
    /// ## 責任
    ///
    /// - 写真撮影完了イベントの受信
    /// - エラーハンドリング
    /// - SwiftUI へのコールバック実行
    ///
    /// - Note: Coordinator は `CameraView` の内部クラスとして定義されています。
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {

        /// 親ビュー（CameraView）への参照
        ///
        /// CameraView は構造体なので、循環参照の心配はありません。
        let parent: CameraView
        
        /// 写真処理完了時のコールバック
        ///
        /// SwiftUI 側で定義されたクロージャーを保持します。
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

        /// Coordinator を初期化します
        ///
        /// - Parameters:
        ///   - parent: 親の CameraView
        ///   - didFinishProcessingPhoto: 撮影完了時のコールバック
        init(_ parent: CameraView,
             didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
            self.parent = parent
            self.didFinishProcessingPhoto = didFinishProcessingPhoto
        }

        /// 写真処理完了時に呼ばれるデリゲートメソッド
        ///
        /// AVFoundation が写真撮影を完了したときに自動的に呼ばれます。
        ///
        /// - Parameters:
        ///   - output: 写真出力オブジェクト
        ///   - photo: キャプチャされた写真データ
        ///   - error: エラー（存在する場合）
        ///
        /// ## 動作
        ///
        /// - エラーがある場合: `.failure(error)` を返す
        /// - 成功した場合: `.success(photo)` を返す
        ///
        /// - Note: このメソッドは Background Queue で呼ばれる可能性があるため、
        ///   UI 更新を行う場合は Main Queue にディスパッチしてください。
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                // エラーがある場合、エラーをコールバック
                parent.didFinishProcessingPhoto(.failure(error))
                return
            }
            // 処理が成功した場合、AVCapturePhotoをコールバック
            parent.didFinishProcessingPhoto(.success(photo))
        }
    }
}
