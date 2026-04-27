//
//  SplashView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 12/04/26.
//

import SwiftUI

struct SplashView: View {
    
    @State private var isReadyToNavigate: Bool = false
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
           
                VStack(spacing : 20){
                    Image("img_logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 5)
                
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationDestination(
                isPresented: $isReadyToNavigate,
            ){
                if isFirstTime {
                    IdleView()
                }else{
                    HomeView()
                }
                
            
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isReadyToNavigate = true
                }
            }
            
        }
        .padding()

    }
}

#Preview {
    SplashView()
}
