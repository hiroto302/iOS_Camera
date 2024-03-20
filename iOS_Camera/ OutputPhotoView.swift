import SwiftUI
import CoreImage.CIFilterBuiltins

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // モノクロームに加工した画像を保持する変数
    @State private var monochromeImage: UIImage?

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
                        saveImageToDocumentsDirectory(monochromeImage!)
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

    // 撮影した画像をアプリ内の Document ディレクトリに保存する処理
    func saveImageToDocumentsDirectory(_ image: UIImage) {
        // ドキュメントディレクトリのFileURLを取得
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // UIImageをData型に変換
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        // 保存するファイル名の決定 と URLの作成
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        // Data型のデータをドキュメントディレクトリに書き込む
        do {
            try imageData.write(to: fileURL)
            print("Image saved to \(fileURL.path)")
        } catch {
            print("Error saving image: \(error)")
        }
    }

    // テスト用: Document から撮影した画像をロードする処理
    func loadImageFromDocumentsDirectory(fileName: String) -> UIImage? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("\(fileName).jpg")

        do {
            let imageData = try Data(contentsOf: fileURL)
            if let image = UIImage(data: imageData) {
                return image
            } else {
                print("Failed to convert data to UIImage")
                return nil
            }
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
}

