//
//  SketchDashboardView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import PencilKit

struct SketchDashboardView: View {
    let selectedImage: UIImage
    @ObservedObject var detector: HumanBodyPose2DDetector
    
    @State private var isMenuOpen: Bool = false
    @State private var isDrawingMode: Bool = false
    @State private var isNavigateToHome: Bool = false
    
    // Make sure your PencilKitCanvas struct is accessible in this file
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        
        NavigationStack {
            
            // Align to top so the custom floating UI stays at the top of the screen
            ZStack(alignment: .top) {
                
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                // ==========================================
                // 1. COMBINED SKETCH & CANVAS LAYER
                // ==========================================
                ZStack {
                    AnimeSketchSceneView(
                        selectedImage: selectedImage,
                        detector: detector,
                        selectedStyle: .manga
                    )
                    
                    PencilKitCanvas(canvasView: $canvasView, isDrawingMode: $isDrawingMode)
                        .allowsHitTesting(isDrawingMode)
                }
                .aspectRatio(selectedImage.size.width > 0 ? selectedImage.size : CGSize(width: 3, height: 4), contentMode: .fit)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .ignoresSafeArea(.keyboard)
                
                
                // ==========================================
                // 2. FLOATING UI LAYER (Top Layer)
                // ==========================================
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- CUSTOM HEADER (iOS 26 Style) ---
                    HStack {
                        // Left: Custom Menu Button
                        CircleButtonView(
                            iconName: "line.3.horizontal",
                            bgColor: .white,
                            tintColor: .black,
                            hasShadow: true,
                            action: {
                                isMenuOpen.toggle()
                            }
                        )
                        .frame(width: 50, height: 50)
                        
                        // Attach the popover menu directly to this button
                        .popover(isPresented: $isMenuOpen, arrowEdge: .top) {
                            VStack(alignment: .leading, spacing: 30) {
                                Button(action: {
                                    
                                    isMenuOpen = false
                                    
                                    isNavigateToHome = true
                                    
                                }) {
                                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                                        .foregroundColor(.primary)
                                }
                                Button(action: {
                                    if let img = exportCombinedImage() {
                                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                    }
                                    isMenuOpen = false
                                }) {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    if let img = exportCombinedImage() {
                                        let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first,
                                           let rootVC = window.rootViewController {
                                            av.popoverPresentationController?.sourceView = rootVC.view
                                            rootVC.present(av, animated: true)
                                        }
                                    }
                                    isMenuOpen = false
                                }) {
                                    Label("Export", systemImage: "photo.on.rectangle")
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(20)
                            .frame(width: 200)
                            .presentationCornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Right: Custom Pencil Toggle Button
                        CircleButtonView(
                            // Dynamically change icon based on state
                            iconName: isDrawingMode ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle",
                            // Change background color when active
                            bgColor: isDrawingMode ? Color(uiColor: .systemBlue) : Color(uiColor: .darkGray),
                            tintColor: .white,
                            hasShadow: true,
                            action: {
                                withAnimation(.spring()) {
                                    isDrawingMode.toggle()
                                }
                            }
                        )
                        .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 220)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        .clipped()
                    
                }
            }
            .navigationDestination(isPresented: $isNavigateToHome){
                HomeView()
            }
            .navigationBarHidden(true)
        }
    }
    
    @MainActor
    private func exportCombinedImage() -> UIImage? {
        let screen = canvasView.window?.windowScene?.screen
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen
        let scale = screen?.scale ?? 1
        let fallbackSize = selectedImage.size.width > 0 ? selectedImage.size : CGSize(width: 1024, height: 1365)
        let size = canvasView.bounds.size.width > 0 ? canvasView.bounds.size : (screen?.bounds.size ?? fallbackSize)
        
        let rendererView = AnimeSketchSceneView(
            selectedImage: selectedImage,
            detector: detector,
            selectedStyle: .manga
        )
        .frame(width: size.width, height: size.height)
        
        let renderer = ImageRenderer(content: rendererView)
        renderer.scale = scale
        guard let sketchImage = renderer.uiImage else { return nil }
        
        let drawingImage = canvasView.drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        sketchImage.draw(in: CGRect(origin: .zero, size: size))
        drawingImage.draw(in: CGRect(origin: .zero, size: size))
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}

#Preview {
    SketchDashboardView(selectedImage: UIImage(), detector: HumanBodyPose2DDetector())
}
