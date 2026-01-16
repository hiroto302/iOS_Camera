import Foundation
import AVFoundation

/// カメラ機能を提供するサービスクラス
///
/// このクラスは AVFoundation を使用したカメラ制御の中核を担います。
/// カメラセッションの管理、デバイス設定、写真撮影などの機能を提供します。
///
/// ## 主な機能
///
/// - カメラセッションの開始と管理
/// - カメラ権限の確認と要求
/// - 前面/背面カメラの切り替え
/// - フォーカスモードの変更
/// - フラッシュ制御
/// - ミラーリング設定
/// - 写真撮影
///
/// ## 使用例
///
/// ```swift
/// let cameraService = CameraService()
/// cameraService.start(delegate: self) { error in
///     if let error = error {
///         print("カメラ起動エラー: \(error)")
///     }
/// }
/// ```
///
/// - Important: このクラスを使用する前に、Info.plist に `NSCameraUsageDescription` キーを追加してください。
/// - Note: カメラセッションは Background Queue で実行されます。
class CameraService {

    /// AVCaptureSession インスタンス
    ///
    /// カメラのキャプチャセッションを管理します。
    /// セットアップ完了後に非 nil となります。
    var session: AVCaptureSession?
    
    /// 写真出力用のオブジェクト
    ///
    /// 撮影した写真データを受け取るために使用します。
    let output = AVCapturePhotoOutput()
    
    /// カメラプレビュー用のレイヤー
    ///
    /// UI に表示するカメラプレビューを提供します。
    /// - Note: このレイヤーを View のサブレイヤーとして追加してください。
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    /// 写真撮影のデリゲート
    ///
    /// `AVCapturePhotoCaptureDelegate` プロトコルを実装したオブジェクト。
    /// 撮影完了時のコールバックを受け取ります。
    var delegate: AVCapturePhotoCaptureDelegate?

    /// 現在使用中のカメラデバイス
    ///
    /// カメラの切り替えや設定変更時に使用します。
    private var device: AVCaptureDevice?

    /// カメラサービスを開始します
    ///
    /// カメラの権限を確認し、許可されている場合はセッションを開始します。
    /// 初回起動時は自動的にユーザーに権限を要求します。
    ///
    /// - Parameters:
    ///   - delegate: 写真撮影時のデリゲート
    ///   - completion: セットアップ完了時に呼ばれるコールバック。エラーがある場合は Error が渡されます。
    ///
    /// - Important: このメソッドを呼ぶ前に、Info.plist に適切な権限説明を追加してください。
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
    }

    /// カメラ使用権限を確認します
    ///
    /// 現在の権限ステータスを確認し、適切な処理を実行します。
    ///
    /// - Parameter completion: 権限確認後のコールバック
    ///
    /// ## 権限ステータスごとの動作
    ///
    /// - `.notDetermined`: ユーザーに権限を要求
    /// - `.authorized`: 即座にカメラセットアップを開始
    /// - `.denied` / `.restricted`: 何もしない（改善の余地あり）
    ///
    /// - Note: 権限要求は非同期で行われ、結果は Main Queue で返されます。
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // 許可されていない場合
        case .notDetermined:
            // ユーザーに使用許可を求める
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    // 使用許可を得たらカメラを設定
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted: // 制限されている場合
            break
        case .denied:     // 拒否された場合
            break
        case .authorized: // 許可されている場合 (一度アプリを起動して既に許可されている場合)
            setupCamera(completion: completion)
        @unknown default: // 未知の状態の場合
            break
        }
    }
    
    /// カメラをセットアップします
    ///
    /// AVCaptureSession を構成し、入力デバイス、出力、プレビューレイヤーを設定します。
    /// 既存のセッションがある場合は、それを停止してから新しいセッションを構成します。
    ///
    /// - Parameters:
    ///   - settingDevice: 使用するカメラデバイス。デフォルトはシステムのデフォルトカメラ。
    ///   - completion: セットアップ完了時のコールバック
    ///
    /// - Note: セッションの開始は Background Queue で実行されます。
    ///
    /// ## セットアップの流れ
    ///
    /// 1. 既存セッションの停止とクリーンアップ
    /// 2. 新しいセッションの作成
    /// 3. Input (カメラデバイス) の追加
    /// 4. Output (写真出力) の追加
    /// 5. Preview Layer の設定
    /// 6. セッションの開始
    private func setupCamera(settingDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video), completion: @escaping (Error?) -> ()) {
        //  既にあるセッションの 停止/ Input・Output の削除 (deviceの更新時のために実行する必要がある）
        self.session?.stopRunning()
        self.session?.inputs.forEach { self.session?.removeInput($0) }
        self.session?.outputs.forEach { self.session?.removeOutput($0) }
        self.session = nil

        let session = AVCaptureSession()
        if let device = settingDevice {
            do {
                // 使用デバイスの決定
                let input = try AVCaptureDeviceInput(device: device)

                // Input・Output を Session に追加
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }

                /* Portrait Matte 対応
                if output.isDepthDataDeliverySupported {
                    session.sessionPreset = .photo
                    // 下記を true にする必要がある
                    output.isDepthDataDeliveryEnabled = true
                    output.isPortraitEffectsMatteDeliveryEnabled = output.isPortraitEffectsMatteDeliverySupported
                    output.enabledSemanticSegmentationMatteTypes = output.availableSemanticSegmentationMatteTypes
                }
                 */

                // PreviewLayer を Session に追加
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session

                // セッション開始
                DispatchQueue.global(qos: .background).async {
                    session.startRunning()
                }
                // 各変数を保持
                self.session = session
                self.device = device
            } catch {
                completion(error)
            }
        }
    }
    
    /// 前面カメラと背面カメラを切り替えます
    ///
    /// 現在のカメラ位置を確認し、反対側のカメラに切り替えます。
    /// 切り替え後は自動的にセッションを再セットアップします。
    ///
    /// - Parameter completion: 切り替え完了時のコールバック
    ///
    /// ## 動作
    ///
    /// - 背面カメラ → 前面カメラ
    /// - 前面カメラ → 背面カメラ
    ///
    /// - Note: 切り替え時にセッションが一時的に停止します。
    func switchCameraPosition(completion: @escaping (Error?) -> ()) {
        // カメラの位置切り替え
        guard let currentDevice = device else { return }
        let newPosition: AVCaptureDevice.Position = currentDevice.position == .back ? .front : .back
        device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
        // 切り替え後、再度セットアップ実行
        setupCamera(settingDevice: device, completion: completion)
    }

    /// カメラのフォーカスモードを切り替えます
    ///
    /// オートフォーカス (`.autoFocus`) と連続オートフォーカス (`.continuousAutoFocus`) を切り替えます。
    ///
    /// - Parameter completion: 切り替え完了時のコールバック
    ///
    /// ## フォーカスモード
    ///
    /// - `.autoFocus`: タップ時など、必要なときにフォーカス
    /// - `.continuousAutoFocus`: 常に自動的にフォーカスを調整
    ///
    /// - Note: `.locked` モードは現在実装していません。
    func switchCameraFocusMode(completion: @escaping (Error?) -> ()) {
        do {
            try device!.lockForConfiguration()
            device!.focusMode = device?.focusMode == .continuousAutoFocus ? .autoFocus : .continuousAutoFocus
            device!.unlockForConfiguration()
            // 切り替え後、再度セットアップ実行
            setupCamera(settingDevice: device, completion: completion)
        } catch {
            print(completion)
        }
    }

    /// カメラ映像のミラーリングを切り替えます
    ///
    /// 出力画像の左右反転を制御します。
    ///
    /// ## ミラーリング動作
    ///
    /// - フロントカメラ + ミラーなし (`.isVideoMirrored = false`) → 反転なし
    /// - リアカメラ + ミラーなし (`.isVideoMirrored = false`) → 反転あり
    ///
    /// - Important: `automaticallyAdjustsVideoMirroring` は常に `false` に設定してください。
    ///   カメラ切り替え時に自動的に `.isVideoMirrored = false` にリセットされます。
    ///
    /// - Note: プレビュー表示には影響せず、出力画像のみに適用されます。
    func switchMirrorView() {
        session?.beginConfiguration()
        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored.toggle()
            } else {
                connection.isVideoMirrored = !connection.isVideoMirrored
            }
        }
        session?.commitConfiguration()
    }

    /// フラッシュモードを反転した値を返します
    ///
    /// 現在のフラッシュモードを受け取り、オン/オフを切り替えた値を返します。
    ///
    /// - Parameter flashMode: 現在のフラッシュモード
    /// - Returns: 切り替え後のフラッシュモード (`.on` ↔ `.off`)
    ///
    /// ## 使用例
    ///
    /// ```swift
    /// let newFlashMode = cameraService.getSwitchedFlashMode(flashMode: .off)
    /// // newFlashMode は .on
    /// ```
    func getSwitchedFlashMode(flashMode: AVCaptureDevice.FlashMode) -> AVCaptureDevice.FlashMode {
        let switchedFlashMode: AVCaptureDevice.FlashMode = flashMode == .off ? .on : .off
        return switchedFlashMode
    }

    /// 写真を撮影します
    ///
    /// 指定された設定で写真を撮影します。撮影完了時は、`start(delegate:completion:)` で
    /// 指定したデリゲートのメソッドが呼ばれます。
    ///
    /// - Parameters:
    ///   - settings: キャプチャ設定。デフォルトは `AVCapturePhotoSettings()`
    ///   - flashMode: フラッシュモード (`.on` または `.off`)
    ///
    /// - Important: デバイスがフラッシュをサポートしていない場合、自動的に `.off` に設定されます。
    ///
    /// ## Portrait Effects Matte 対応
    ///
    /// Portrait Effects Matte を有効にする場合は、コメントアウトされたコードを参照してください。
    /// 深度データとポートレートマットの配信が必要です。
    ///
    /// - Note: デリゲートメソッド `photoOutput(_:didFinishProcessingPhoto:error:)` で結果を受け取ります。
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), flashMode: AVCaptureDevice.FlashMode) {
        
        // フラッシュモードに対応している場合は設定を適用する
        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = flashMode
        } else {
            settings.flashMode = .off
        }

        /* Portrait Matte 対応
         if self.output.isDepthDataDeliverySupported {
             settings.isPortraitEffectsMatteDeliveryEnabled = true
             settings.isDepthDataDeliveryEnabled = true
             settings.embedsDepthDataInPhoto = true
             settings.embedsPortraitEffectsMatteInPhoto = true
         }
        */

        output.capturePhoto(with: settings, delegate: delegate!)
    }

    /* Portrait Matte 対応
    func setDeviceForPortraitMatte() -> AVCaptureDevice
    {
        // 下記のどちらかのデバイスが対応している
        return AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)!
       return settingDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)!
    }
     */
}
