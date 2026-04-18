//
//  ContentView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import PhotosUI // 1. IMPORTANT: Import the PhotosUI framework

struct IdleView: View {
    

    @State private var selectedCameraImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isShowingCamera: Bool = false
    @State private var navigateToTransform: Bool  = false
    
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 30) {
                
                VStack(spacing: 30) {
                    Text("Sketsain")
                        .font(
                            .system(
                                size: 80,
                                weight: .bold
                            )
                        )
                        
                    
                    HStack(spacing: 10){
                        Spacer()
                        Image("img_default")
                            .resizable()
                            .frame(width: 170, height: 170)
                        
                        Spacer()
                        
                        Image("img_default")
                            .resizable()
                            .frame(width: 170, height: 170)
                        
                        Spacer()
                        
                        Image("img_default")
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
                    .onChange(of: selectedItem) { newItem in
                        print("A photo was selected from the gallery!")
                        navigateToTransform = true
                    }
                    
                    
                    
                    Button(action: {
                        isShowingCamera = true
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
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedCameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedCameraImage) { newImage in
                if newImage != nil {
                    print("A photo was taken with the camera!")
                    navigateToTransform = true
                }
            }
            .navigationDestination(isPresented: $navigateToTransform) {
                            LoadingView()
                
            }
       
      

          
        }
        .padding()
   
        
    
    }
}

#Preview {
    IdleView()
}
