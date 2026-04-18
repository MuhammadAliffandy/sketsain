//
//  ContentView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI

struct LoadingView: View {
    
    @State private var isActive: Bool = false
    @State private var progressValue: Float = 0.8
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
           
                Image("img_default")
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
               
                UIKitProgressView(
                    progress: $progressValue,
                    trackColor: .systemGray5,
                    progressColor: .systemBlue
                )
                .frame(height: 50)
                .padding(.horizontal, 120)
                
                
                
            }
            .padding()
            .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            .navigationDestination(isPresented: $isActive) {
                    SketchDashboardView()
            }
        }
    }
}

#Preview {
    LoadingView()
}
