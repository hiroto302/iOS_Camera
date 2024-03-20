import SwiftUI
import CoreImage.CIFilterBuiltins

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // モノクロームに加工した画像を保持する変数
    @State private var monochromeImage: UIImage?
    let cameraAppDocumentDirectory = CameraAppDocumentsDirectory()

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
                        cameraAppDocumentDirectory.saveImageToDocumentsDirectory(monochromeImage!)
                    }, label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    })
                }
                .padding()
            }
        }
    }
}

