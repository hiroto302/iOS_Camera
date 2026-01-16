import SwiftUI
import AVFoundation

/// カスタムカメラUIのメインビュー
///
/// CameraView をカスタマイズし、カメラ設定ボタン、シャッターボタン、カウントダウン表示などの
/// UI コンポーネントを統合したメインのカメラ画面です。
///
/// ## 主な機能
///
/// - カメラプレビューの表示
/// - カメラ設定の変更（フラッシュ、カメラ位置、フォーカス、ミラーリング）
/// - カウントダウン撮影
/// - 設定変更時のポップアップメッセージ
/// - 撮影後の画像表示画面への遷移
///
/// ## UI 構成
///
/// ```
/// ┌──────────────────────────┐
/// │  [設定ボタン群]           │
/// │                          │
/// │    [カメラプレビュー]      │
/// │                          │
/// │  [シャッターボタン]        │
/// └──────────────────────────┘
/// ```
///
/// - Note: このビューは SwiftUI の宣言的な構文で構築されており、状態変更が自動的に UI に反映されます。
struct CustomCameraView: View {

    /// カメラサービスのインスタンス
    ///
    /// カメラセッションとデバイス制御を管理します。
    let cameraService = CameraService()
    
    /// フラッシュモードの設定
    ///
    /// `.on` または `.off` を保持します。
    @State var flashMode: AVCaptureDevice.FlashMode = .off
    
    /// 連続オートフォーカスモードが有効かどうか
    ///
    /// - `true`: 連続オートフォーカス (`.continuousAutoFocus`)
    /// - `false`: オートフォーカス (`.autoFocus`)
    @State var isContinuousAutoFocus = true

    /// 撮影された画像
    ///
    /// 撮影成功時に `UIImage` が格納されます。
    @State var capturedImage: UIImage?
    
    /// 出力画面（OutputPhotoView）を表示するかどうか
    ///
    /// `true` のときに撮影後の画像確認画面が表示されます。
    @State private var isOutputPhotoViewPresented = false

    /// カウントダウンタイマー
    ///
    /// 撮影前の3秒カウントダウンを管理します。
    @ObservedObject var countDownTimer = CountDownTimer()
    
    /// 設定変更時のメッセージを表示するかどうか
    ///
    /// `true` のときにポップアップメッセージが表示されます。
    @State var isShowingSettingMessage: Bool = false
    
    /// 表示する設定メッセージの内容
    ///
    /// 各設定ボタンがタップされたときに更新されます。
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

                        /* PortraitEffectMatte 対応
                        if (photo.portraitEffectsMatte != nil) {
                            let resolvedSettings = photo.resolvedSettings
                            // portraitEffectsMatte を利用した処理
                        }
                         */

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

/// カメラ設定ボタンコンポーネント
///
/// フラッシュ、カメラ切り替え、フォーカスモードなどの設定を変更するボタン。
///
/// - Parameters:
///   - action: ボタンタップ時に実行されるアクション
///   - imageName: SF Symbols の画像名
///
/// ## 使用例
///
/// ```swift
/// SettingCameraButton(
///     action: { cameraService.switchCameraPosition() },
///     imageName: "camera.rotate.fill"
/// )
/// ```
struct SettingCameraButton: View {
    /// ボタンタップ時に実行されるアクション
    var action: () -> Void
    
    /// SF Symbols の画像名
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

/// カメラ映像のミラーリング切り替えボタン
///
/// 出力画像の左右反転を切り替えるための特殊なボタン。
/// ボタンタップ時にポップアップメッセージを表示します。
///
/// - Parameters:
///   - cameraService: カメラサービスのインスタンス
///   - isShowingSettingMessage: メッセージ表示フラグ（バインディング）
///   - settingMessage: メッセージ内容（バインディング）
struct OutputImageMirrorButton: View {
    /// カメラサービスのインスタンス
    @State var cameraService: CameraService
    
    /// メッセージ表示フラグ
    @Binding var isShowingSettingMessage: Bool
    
    /// メッセージ内容
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

/// カメラ設定変更時のポップアップメッセージビュー
///
/// 設定ボタンがタップされたときに一時的に表示されるメッセージ。
/// 1秒後に自動的に非表示になります。
///
/// - Parameters:
///   - isShowingSettingMessage: メッセージ表示フラグ（バインディング）
///   - settingMessage: 表示するメッセージ内容（バインディング）
///
/// ## デザイン
///
/// - 背景: 半透明の黒 (opacity: 0.7)
/// - テキスト色: 白
/// - 角丸: 10pt
///
/// - Note: `onAppear` で自動的に1秒後に非表示になるタイマーが設定されます。
struct PopupSettingMessageView: View {
    /// メッセージ表示フラグ
    @Binding var isShowingSettingMessage: Bool
    
    /// 表示するメッセージ内容
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

/// シャッターボタンコンポーネント
///
/// カウントダウン中は数字を表示し、通常時は撮影ボタンを表示します。
///
/// ## 状態による表示の切り替え
///
/// - カウントダウン中: 白い円の中に青字でカウント数を表示
/// - 通常時: 白い円形のシャッターボタン
///
/// ## 動作フロー
///
/// 1. ボタンタップ
/// 2. 3秒カウントダウン開始
/// 3. カウントダウン完了
/// 4. 自動的に写真撮影
///
/// - Parameters:
///   - countDownTimer: カウントダウンタイマー
///   - cameraService: カメラサービス
///   - flashMode: フラッシュモード（バインディング）
struct ShutterButton: View {

    /// カウントダウンタイマー
    @ObservedObject var countDownTimer: CountDownTimer
    
    /// カメラサービス
    @State var cameraService: CameraService
    
    /// フラッシュモード
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
