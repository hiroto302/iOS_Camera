import SwiftUI
import CoreImage.CIFilterBuiltins

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // モノクロームに加工した画像を保持する変数
    @State private var monochromeImage: UIImage?
    let cameraAppDocumentDirectory = CameraAppDocumentsDirectory()
    // アプリの Document ディレクトリに保存するか確認アラート フラグ
    @State var isShownSaveAlert = false

    var body: some View {
        ZStack {
            // 撮影された画像を全画面で表示
            if let image = MonochromeImage().translateColorMonochrome(from: capturedImage!) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .onAppear {
                        monochromeImage = image
                        // カメラロールへの保存処理
                        // TODO: 許可されなかった時のエラー対応・アプリ起動時に使用許可要求を検討
                        UIImageWriteToSavedPhotosAlbum(monochromeImage!, nil, nil, nil)
                    }
            } else {
                Color(UIColor.systemBackground)
            }

            VStack {
                Spacer()
                HStack{
                    Spacer()
                    Spacer()
                    Button(action: {
                        // 遷移前の画面に戻る
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    })
                    Spacer()
                    // モノクロ画像をドキュメントディレクトリに保存
                    Button(action: {
                        isShownSaveAlert = true

                    }, label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    })
                    .alert("Document ディレクトリに画像を保存しますか？", isPresented: $isShownSaveAlert) {
                        Button("保存する", role: .destructive){
                            cameraAppDocumentDirectory.saveImageToDocumentsDirectory(monochromeImage!)
                        }
                        Button("キャンセル", role: .cancel) {
                        }
                    } message: {
                        Text("アプリ内に保存されます")
                    }
                }
                .padding()
            }
        }
    }
}

