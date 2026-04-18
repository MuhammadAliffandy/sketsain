import SwiftUI
import PencilKit

struct Canvas: UIViewRepresentable {
    
    @Binding var canvasView: PKCanvasView
    
    @State private var toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        
        canvasView.drawingPolicy = .anyInput

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {

    }
}
