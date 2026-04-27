//
//  ContentView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI

struct LoadingView: View {
    let selectedImage: UIImage
    @StateObject private var detector = HumanBodyPose2DDetector()
    @State private var isActive: Bool = false
    @State private var progressValue: Float = 0.1
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
           
                Image("img_transform")
                    .resizable()
                    .frame(width: 365, height: 365)
                
                
                VStack(spacing: 10){
                    Text("Transforming")
                        .font(.system(size: 58))
                        .bold()
                    
                    Text("Dont close your Ipad or Iphone! it was\ntransforming your photos")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30))
                }
               
                ProgressIndicatorView(
                    progress: $progressValue,
                    trackColor: Color(uiColor: .systemGray5),
                    progressColor: Color(uiColor: .systemBlue)
                )
                .frame(height: 50)
                .padding(.horizontal, 120)
                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                Task {
                    withAnimation(.linear(duration: 2.0)) {
                        progressValue = 1.0
                    }
                    
                    let startTime = Date()
                    await detector.runHumanBodyPose2DRequestOnImage(uiImage: selectedImage)
                    
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed < 2.0 {
                        try? await Task.sleep(nanoseconds: UInt64((2.0 - elapsed) * 1_000_000_000))
                    }
                    
                    await MainActor.run {
                        self.isActive = true
                    }
                }
            }
            .navigationDestination(isPresented: $isActive) {
                SketchDashboardView(selectedImage: selectedImage, detector: detector)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoadingView(selectedImage: UIImage(systemName: "photo") ?? UIImage())
}
