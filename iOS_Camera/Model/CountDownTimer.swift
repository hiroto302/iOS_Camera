import Foundation
import SwiftUI

// カウントダウンタイマー クラス
class CountDownTimer : ObservableObject {
    var timer: Timer?
    @Published var time: Int = 0
    @Published var isCounting: Bool = false
    var onCompletion: (() -> Void)?

    func start(settingTime: Int) {
        self.isCounting = true
        self.time = settingTime

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.time > 1 {
                self.time -= 1
            } else{
                self.timer?.invalidate()
                self.timer = nil
                self.isCounting = false
                self.onCompletion?()
            }
        }
    }
}
