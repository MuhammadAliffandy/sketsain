import SwiftUI
import PencilKit


struct PencilKitCanvas: UIViewRepresentable {
    
    @Binding var canvasView: PKCanvasView
    @Binding var isDrawingMode: Bool
    @State private var toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        toolPicker.addObserver(canvasView)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if isDrawingMode {
            uiView.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: uiView)
        } else {
            uiView.resignFirstResponder()
            toolPicker.setVisible(false, forFirstResponder: uiView)
        }
    }
}
