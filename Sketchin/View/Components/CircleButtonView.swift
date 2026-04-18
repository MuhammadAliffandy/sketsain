import SwiftUI
import UIKit

struct UIKitCircleButton: UIViewRepresentable {
    var iconName: String
    var bgColor: UIColor
    var tintColor: UIColor
    var hasShadow: Bool
    var action: () -> Void

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        uiView.setImage(image, for: .normal)
        uiView.backgroundColor = bgColor
        uiView.tintColor = tintColor
        uiView.layer.cornerRadius = 22.5
        
        if hasShadow {
            uiView.layer.shadowColor = UIColor.black.cgColor
            uiView.layer.shadowOpacity = 0.1
            uiView.layer.shadowOffset = CGSize(width: 0, height: 2)
            uiView.layer.shadowRadius = 4
        } else {
            uiView.layer.shadowOpacity = 0
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func buttonTapped() { action() }
    }
}
