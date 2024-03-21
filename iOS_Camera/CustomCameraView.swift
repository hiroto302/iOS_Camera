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
    // 設定ボタン押した時に出現するメッセージ変数
    @State var isShowingSettingMessage: Bool = false
    @State var settingMessage: String = ""

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
                HStack{
                    // 撮影時のフラッシュ切り替え
                    SettingCameraButton(action: {
                        flashMode = cameraService.getSwitchedFlashMode(flashMode: flashMode)
                    }, imageName: flashMode == .on ? "flashlight.on.fill" : "flashlight.slash")
                    Spacer()
                    // 前後カメラの切り替え
                    SettingCameraButton(action: {
                        cameraService.switchCameraPosition { error in
                            if let error = error {
                                print(error)
                            }
                        }
                    }, imageName: "camera.rotate.fill")
                    Spacer()
                    // フォーカス切り替え
                    SettingCameraButton(action: {
                        cameraService.switchCameraFocusMode { error in
                            if let error = error {
                                print(error)
                            }
                        }
                        isContinuousAutoFocus.toggle()
                    }, imageName: isContinuousAutoFocus == true ? "camera.metering.partial" : "camera.metering.none")
                    Spacer()
                    // カメラの表示映像の反転切り替え (出力画像の左右反転)
                    OutputImageMirrorButton(cameraService: cameraService, isShowingSettingMessage: $isShowingSettingMessage, settingMessage: $settingMessage)
                }
                .padding()
                // シャッターボタンを押してカウントダウン中、設定変更 無効
                .disabled(countDownTimer.isCounting)
                .opacity(countDownTimer.isCounting ? 0.0 : 1.0)
                // カメラ設定ボタンが押された時、出現するメッセージ
                PopupSettingMessageView(isShowingSettingMessage: $isShowingSettingMessage, settingMessage: $settingMessage)
                Spacer()
                // シャッターボタン
                ShutterButton(countDownTimer: countDownTimer, cameraService: cameraService, flashMode: $flashMode)
            }
        }
        // OutputPhotoView へ遷移
        .sheet(isPresented: $isOutputPhotoViewPresented, content: {
            OutputPhotoView(capturedImage: $capturedImage)
        })
    }
}

// 各カメラ設定ボタン
struct SettingCameraButton: View {
    var action: () -> Void
    var imageName: String

    var body: some View {
        Button(action: action) {
            Image(systemName: "\(imageName)")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding(.bottom)
        }
    }
}

// カメラの表示映像の反転切り替えボタン
    struct OutputImageMirrorButton: View {
        @State var cameraService: CameraService
        @Binding var isShowingSettingMessage: Bool
        @Binding var settingMessage: String

        var body: some View {
            Button(action: {
                cameraService.switchMirrorView()
                isShowingSettingMessage = true
                settingMessage = "撮影写真を左右反転"
            }, label: {
                Image(systemName: "photo.artframe")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .opacity(0.5)
                    .padding(.bottom)
                    .overlay(Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding(.bottom))
            })
        }
    }

// カメラ設定ボタンがクリックされたときに出現する View
struct PopupSettingMessageView: View {
    @Binding var isShowingSettingMessage: Bool
    @Binding var settingMessage: String

    var body: some View {
        if isShowingSettingMessage
        {
            Text("\(settingMessage)")
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isShowingSettingMessage = false
                    }
                }
        }    }
}

// シャッターボタン
struct ShutterButton: View {

    @ObservedObject var countDownTimer: CountDownTimer
    @State var cameraService: CameraService
    @Binding var flashMode: AVCaptureDevice.FlashMode

    var body: some View {
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
                Image(systemName: "circle")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                    .padding(.bottom)
                    .overlay(Image(systemName: "circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .padding(.bottom))
            })
        }
    }
}


#Preview {
    CustomCameraView()
}
