import Foundation
import SwiftUI

class CameraAppDocumentsDirectory{
    
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
            // セーブ先の確認
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
