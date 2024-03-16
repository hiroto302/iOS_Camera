import SwiftUI
import AVFoundation

// SwiftUIでカメラプレビューを表示するためのビューコンポーネント
struct CameraView: UIViewControllerRepresentable {

    // 利用したい ViewController を typealiasで指定
    typealias UIViewControllerType = UIViewController
    // CameraServiceインスタンス
    let cameraService: CameraService
    // 非同期で完了する写真撮影処理の結果を受け取り、成功時と失敗時でそれぞれ異なる処理を行うこと可能とする Result
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

    // makeUIViewController : CameraViewが作られた時に呼ばれる関数
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


    // Coordinatorのファクトリーメソッド
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }

    // updateUIViewController : Viewが更新されたときに呼ばれる関数(SwiftUIから更新が必要になった時)
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }


    // Coordinator : AVCapturePhotoのキャプチャを処理を担当
    // ViewController から SwiftUIビュー にdelegateメッセージを転送するためにコーディネーターを使用
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {

        let parent: CameraView
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

        init(_ parent: CameraView,
             didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
            self.parent = parent
            self.didFinishProcessingPhoto = didFinishProcessingPhoto
        }

        // AVCapturePhotoが処理されるときに呼び出される
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
