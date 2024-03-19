import Foundation
import AVFoundation

// カメラ機能を提供するクラス
class CameraService {

    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var delegate: AVCapturePhotoCaptureDelegate?

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
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                // 使用デバイスの決定
                // TODO: 前後のカメラを使用できるように検討
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

                session.startRunning()
                self.session = session
            } catch {
                completion(error)
            }
        }
    }

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
