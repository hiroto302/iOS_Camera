import Foundation
import SwiftUI

struct MonochromeImage {

    // モノクローム加工したUI UIImage を出力
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

    // モノクローム加工処理した CIImange を出力
    private func colorMonochrome(inputImage: CIImage) -> CIImage {
        let colorMonochromeFilter = CIFilter.colorMonochrome()
        colorMonochromeFilter.inputImage = inputImage
        colorMonochromeFilter.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
        colorMonochromeFilter.intensity = 1
        return colorMonochromeFilter.outputImage!
    }
}
