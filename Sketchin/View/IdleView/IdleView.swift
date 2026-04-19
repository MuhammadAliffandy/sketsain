//
//  ContentView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import PhotosUI 

struct IdleView: View {

    @AppStorage("isFirstTime") private var isFirstTime: Bool = true

    @State private var selectedCameraImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingCamera: Bool = false
    @State private var navigateToTransform: Bool  = false
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
                
                VStack(spacing: 50) {
                    Text("Sketsain")
                        .font(
                            .system(
                                size: 80,
                                weight: .bold
                            )
                        )
                        
                    
                    HStack(spacing: 10){
                        Spacer()
                        Image("img_onboard")
                            .resizable()
                            .frame(width: 170, height: 170)
                        
                        Spacer()
                        
                        Image("img_onboard2")
                            .resizable()
                            .frame(width: 170, height: 170)
                        
                        Spacer()
                        
                        Image("img_onboard3")
                            .resizable()
                            .frame(width: 170, height: 170)
                        Spacer()
                        
                    }
                    .padding(.horizontal, 250)
                    .frame(maxWidth: .infinity)
                

                    
                    Text("Lets try your photo pose references\n transforming in sketch")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 32))
                
                }
            
                HStack(spacing: 25){
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {

                        Text("Photos")
                            .font(.system(size: 28, weight: .medium))
                            .padding(.horizontal, 70)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .foregroundStyle(Color.white)
                            .cornerRadius(50)
                            .shadow(
                                color: .black.opacity(0.12),
                                radius: 10 ,
                                x: 5,
                                y: 5
                            )
                            
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        if let newItem = newItem {
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                    await MainActor.run {
                                        selectedImage = image
                                        navigateToTransform = true
                                    }
                                }
                            }
                        }
                     
                    }
                    
                    
                    
                    Button(action: {
                        isShowingCamera = true
                        isFirstTime = false
                    }){
                        Text("Camera")
                            .font(.system(size: 28, weight: .medium))
                            .padding(.horizontal, 70)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .foregroundStyle(Color.black)
                            .cornerRadius(50)
                            .shadow(
                                color: .black.opacity(0.12),
                                radius: 10 ,
                                x: 5,
                                y: 5
                            )
                    }
                    
                }
           
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedCameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedCameraImage) { _, newImage in
                if let image = newImage {
                    selectedImage = image
                    navigateToTransform = true
                }
            }
            
            .navigationDestination(isPresented: $navigateToTransform) {
                if let image = selectedImage {
                    LoadingView(selectedImage: image)
                }
            }
            
       
      

          
        }
        .padding()
   
        
    
    }
}

#Preview {
    IdleView()
}
