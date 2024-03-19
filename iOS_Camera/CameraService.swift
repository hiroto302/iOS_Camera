import Foundation
import AVFoundation

// カメラ機能を提供するクラス
class CameraService {

    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var delegate: AVCapturePhotoCaptureDelegate?

    // カメラのデバイス設定変数
    private var device: AVCaptureDevice?

    // カメラ起動時の初期化
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
    }

    // アプリ内でのカメラ使用許可確認
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
    
    // カメラのセットアップ
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

                // PreviewLayer を Session に追加
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session

                // セッション開始
                session.startRunning()
                // 各変数を保持
                self.session = session
                self.device = device
            } catch {
                completion(error)
            }
        }
    }
    
    // 前後(フロント・リア)のカメラ切り替え
    func switchCameraPosition(completion: @escaping (Error?) -> ()) {
        // カメラの位置切り替え
        guard let currentDevice = device else { return }
        let newPosition: AVCaptureDevice.Position = currentDevice.position == .back ? .front : .back
        device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
        // 切り替え後、再度セットアップ実行
        setupCamera(settingDevice: device, completion: completion)
    }

    // カメラのフォーカス切り替え
    // (現時点では、.locked の有用性がないため、.autoFocus と .continuousAutoFocus 設定の切り替えを実装)
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

    /* カメラの映像の反転 on/off 切り替え
     connection.automaticallyAdjustsVideoMirroring は常に false でよい。
     前後(フロント・リア)のカメラ切り替え が実行された時、整合性のために自動で connection.isVideoMirrored = false となる。
     フロントカメラ .isVideoMirrored = false の時、出力画像 反転なし
     リアカメラ    .isVideoMirrored = false の時、出力画像 反転あり
     */
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

    // フラッシュモードの切り替え 取得
    func getSwitchedFlashMode(flashMode: AVCaptureDevice.FlashMode) -> AVCaptureDevice.FlashMode {
        let switchedFlashMode: AVCaptureDevice.FlashMode = flashMode == .off ? .on : .off
        return switchedFlashMode
    }

    // カメラ撮影
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), flashMode: AVCaptureDevice.FlashMode) {
        
        // フラッシュモードに対応している場合は設定を適用する
        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = flashMode
        } else {
            settings.flashMode = .off
        }

        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
