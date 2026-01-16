import Foundation
import SwiftUI

/// モノクローム（白黒）画像変換ユーティリティ
///
/// Core Image の `CIFilter` を使用して、カラー画像をモノクローム画像に変換します。
///
/// ## 使用例
///
/// ```swift
/// let monochromeConverter = MonochromeImage()
/// if let grayImage = monochromeConverter.translateColorMonochrome(from: originalImage) {
///     // モノクローム画像を使用
/// }
/// ```
///
/// - Note: 現在このユーティリティはプロジェクトで未使用ですが、将来的な画像フィルタ機能拡張のために実装されています。
struct MonochromeImage {

    /// カラー画像をモノクローム画像に変換します
    ///
    /// 入力された `UIImage` を白黒のモノクローム画像に変換します。
    /// Core Image の `CIFilter.colorMonochrome()` を使用して処理を行います。
    ///
    /// - Parameter image: 変換元のカラー画像
    /// - Returns: モノクローム変換後の `UIImage`。変換に失敗した場合は `nil`
    ///
    /// ## 変換処理の流れ
    ///
    /// 1. `UIImage` → `CGImage` → `CIImage` に変換
    /// 2. モノクロームフィルタを適用
    /// 3. `CIImage` → `CGImage` → `UIImage` に逆変換
    /// 4. 元画像のスケールと向きを維持
    ///
    /// - Important: 入力画像が `cgImage` を持たない場合（一部の特殊な画像形式）は `nil` を返します。
    ///
    /// ## 使用例
    ///
    /// ```swift
    /// let converter = MonochromeImage()
    /// if let monoImage = converter.translateColorMonochrome(from: colorImage) {
    ///     imageView.image = monoImage
    /// } else {
    ///     print("画像変換に失敗しました")
    /// }
    /// ```
    func translateColorMonochrome(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let ciContext = CIContext(options: nil)

        // CIImageを使用した画像編集処理
        let filteredCIImage = colorMonochrome(inputImage: ciImage)

        guard let cgImage = ciContext.createCGImage(filteredCIImage, from: filteredCIImage.extent) else { return nil }
        let result = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        return result
    }

    /// モノクロームフィルタを適用します
    ///
    /// Core Image の `CIFilter.colorMonochrome()` を使用して、
    /// 入力された `CIImage` にモノクローム効果を適用します。
    ///
    /// - Parameter inputImage: フィルタを適用する元画像
    /// - Returns: モノクローム効果を適用した `CIImage`
    ///
    /// ## フィルタパラメータ
    ///
    /// - **色 (color)**: グレー (R:0.5, G:0.5, B:0.5)
    /// - **強度 (intensity)**: 1.0 (最大)
    ///
    /// - Note: 強度を調整することで、セピア調などの異なる効果も実現できます。
    private func colorMonochrome(inputImage: CIImage) -> CIImage {
        let colorMonochromeFilter = CIFilter.colorMonochrome()
        colorMonochromeFilter.inputImage = inputImage
        colorMonochromeFilter.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
        colorMonochromeFilter.intensity = 1
        return colorMonochromeFilter.outputImage!
    }
}
