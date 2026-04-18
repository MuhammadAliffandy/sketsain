//
//  SplashView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 12/04/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
           
                VStack(spacing : 20){
                    
                    NavigationLink(destination: IdleView()){
                        Image("img_sketsain_logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 5)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    SplashView()
}
