import SwiftUI

// 撮影した画像を表示する View
struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // 撮影された画像を全画面で表示
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color(UIColor.systemBackground)
            }

            VStack {
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
                .padding(.bottom)
            }
        }
    }
}

