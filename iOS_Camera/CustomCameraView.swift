import SwiftUI
import AVFoundation

// CameraView をカスタマイズして UI表示するための SwiftUIView
struct CustomCameraView: View {

    let cameraService = CameraService()
    // カメラのフラッシュモード設定
    @State var flashMode: AVCaptureDevice.FlashMode = .off
    // カメラのフォーカスモード設定
    @State var isContinuousAutoFocus = true

    // 撮影された画像を保持するための変数
    @State var capturedImage: UIImage?
    // 出力画面に移動するか
    @State private var isOutputPhotoViewPresented = false

    // カウントダウンタイマー 変数
    @ObservedObject var countDownTimer = CountDownTimer()

    var body: some View {
        ZStack {
            // CustomCameraView が表示されると、CameraService インスタンスが作成される
            // カメラプレビューと撮影ボタンの表示
            CameraView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    // 撮影した写真からデータを取得し、UIImageに変換
                    if let data = photo.fileDataRepresentation() {
                        capturedImage = UIImage(data: data)
                        // 撮影成功後 OutputPhotoView へ遷移
                        isOutputPhotoViewPresented.toggle()
                    } else {
                        print("Error: no image data found")
                    }
                case .failure(let err):
                    print(err.localizedDescription)
                }
            }
            // 撮影ボタンを中央下部に配置
            VStack {
                // 撮影時のフラッシュ切り替え
                HStack{
                    Button(action: {
                        flashMode = cameraService.getSwitchedFlashMode(flashMode: flashMode)
                    }, label: {
                        Image(systemName: flashMode == .on ? "flashlight.on.fill" : "flashlight.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                    Spacer()
                    // 前後カメラの切り替え
                    Button(action: {
                        cameraService.switchCameraPosition { error in
                            if let error = error {
                                print(error)
                            }
                        }
                    }, label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                    Spacer()
                    // フォーカス切り替え
                    Button(action: {
                        cameraService.switchCameraFocusMode { error in
                            if let error = error {
                                print(error)
                            }
                        }
                        isContinuousAutoFocus.toggle()
                    }, label: {
                        Image(systemName: isContinuousAutoFocus == true ? "camera.metering.partial" : "camera.metering.none")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                    Spacer()
                    // カメラの表示映像の反転切り替え
                    Button(action: {
                        cameraService.switchMirrorView()
                    }, label: {
                        ZStack{
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .opacity(0.5)
                                .padding(.bottom)
                                .overlay(Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding(.bottom))
                        }
                    })
                }
                .padding()
                .disabled(countDownTimer.isCounting)
                .opacity(countDownTimer.isCounting ? 0.0 : 1.0)

                Spacer()
                if countDownTimer.isCounting {
                    ZStack{
                        Circle()
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                        Text("\(countDownTimer.time)")
                            .foregroundStyle(.blue)
                            .font(.largeTitle)
                    }.padding(.bottom)
                } else {
                    // 撮影ボタン
                    Button(action: {
                        // 3秒のカウントダウン開始
                        countDownTimer.start(settingTime: 3)
                        // カウントダウン完了後、撮影
                        countDownTimer.onCompletion = {
                            cameraService.capturePhoto(flashMode: flashMode)
                        }
                    }, label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                }
        }
        // OutputPhotoView へ遷移
        }.sheet(isPresented: $isOutputPhotoViewPresented, content: {
            OutputPhotoView(capturedImage: $capturedImage)
        })
    }
}


#Preview {
    CustomCameraView()
}
