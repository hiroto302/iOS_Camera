import Foundation
import SwiftUI

/// カウントダウンタイマーを管理するクラス
///
/// 撮影前のカウントダウン機能を提供します。
/// `ObservableObject` として実装されているため、SwiftUI のビューと自動的にバインディングできます。
///
/// ## 主な機能
///
/// - カウントダウンの開始と管理
/// - カウント値のリアルタイム更新
/// - カウントダウン完了時のコールバック実行
///
/// ## 使用例
///
/// ```swift
/// @ObservedObject var countDownTimer = CountDownTimer()
///
/// // カウントダウン開始
/// countDownTimer.start(settingTime: 3)
/// countDownTimer.onCompletion = {
///     print("カウントダウン完了！")
/// }
///
/// // UI でカウント値を表示
/// Text("\(countDownTimer.time)")
/// ```
///
/// - Note: タイマーは Main RunLoop で実行され、1秒間隔で更新されます。
class CountDownTimer : ObservableObject {
    /// 内部で使用する Timer インスタンス
    ///
    /// カウントダウン中は非 nil、停止中は nil です。
    var timer: Timer?
    
    /// 現在のカウント値
    ///
    /// カウントダウン中は 1 ずつ減少します。
    /// この値は `@Published` のため、変更時に自動的に UI が更新されます。
    @Published var time: Int = 0
    
    /// カウントダウン実行中かどうか
    ///
    /// `true` の場合、カウントダウン実行中です。
    /// この値を使って UI の表示/非表示を制御できます。
    @Published var isCounting: Bool = false
    
    /// カウントダウン完了時に実行されるコールバック
    ///
    /// カウントが 0 になったときに自動的に呼ばれます。
    ///
    /// ## 使用例
    ///
    /// ```swift
    /// countDownTimer.onCompletion = {
    ///     cameraService.capturePhoto()
    /// }
    /// ```
    var onCompletion: (() -> Void)?

    /// カウントダウンを開始します
    ///
    /// 指定された秒数からカウントダウンを開始し、1秒ごとに値を減らします。
    /// カウントが 0 になると、`onCompletion` コールバックが実行されます。
    ///
    /// - Parameter settingTime: カウントダウンの初期値（秒）
    ///
    /// - Important: カウントダウン中に再度このメソッドを呼ぶと、前のタイマーは無効化されずに
    ///   新しいタイマーが開始されます。必要に応じて事前にチェックしてください。
    ///
    /// ## 動作フロー
    ///
    /// 1. `isCounting` が `true` に設定される
    /// 2. `time` が `settingTime` で初期化される
    /// 3. 1秒ごとに `time` が 1 ずつ減少
    /// 4. `time` が 1 以下になったらタイマーを停止
    /// 5. `onCompletion` を実行
    ///
    /// - Note: タイマーは Main RunLoop で実行されます。
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
