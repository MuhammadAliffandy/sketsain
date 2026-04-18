import SwiftUI
import UIKit


struct UIKitProgressView: UIViewRepresentable {
    
    @Binding var progress: Float
    var trackColor: UIColor
    var progressColor: UIColor

    func makeUIView(context: Context) -> UIProgressView {
        let progressView = UIProgressView(progressViewStyle: .default)
        
        progressView.trackTintColor = trackColor
        progressView.progressTintColor = progressColor
        
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        
        return progressView
    }

    func updateUIView(_ uiView: UIProgressView, context: Context) {
        uiView.setProgress(progress, animated: true)
    }
}
