//
//  SketchDashboardView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import PencilKit

struct SketchDashboardView: View {
    
    @State private var isMenuOpen: Bool = false
    @State private var isDrawingMode: Bool = false
    
    // Make sure your PencilKitCanvas struct is accessible in this file
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        
        NavigationStack {
            
            // Align to top so the custom floating UI stays at the top of the screen
            ZStack(alignment: .top) {
                
                // ==========================================
                // 1. CANVAS LAYER (Bottom Layer)
                // ==========================================
                PencilKitCanvas(canvasView: $canvasView, isDrawingMode: $isDrawingMode)
                    .ignoresSafeArea()
                    .allowsHitTesting(isDrawingMode)
                
                
                // ==========================================
                // 2. FLOATING UI LAYER (Top Layer)
                // ==========================================
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- CUSTOM HEADER (iOS 26 Style) ---
                    HStack {
                        // Left: Custom Menu Button
                        UIKitCircleButton(
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
                                    print("Save to Gallery")
                                    isMenuOpen = false
                                }) {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    print("Export Image")
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
                        UIKitCircleButton(
                            // Dynamically change icon based on state
                            iconName: isDrawingMode ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle",
                            // Change background color when active
                            bgColor: isDrawingMode ? .systemBlue : .darkGray,
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
                    
                
                    Image("img_default")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 220)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    
                }
            }
            // CRITICAL: Hide the default navigation bar!
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SketchDashboardView()
}
