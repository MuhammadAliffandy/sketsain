//
//  SketchDashboardView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import SwiftData
import PencilKit
import Vision

struct SketchDashboardView: View {
    let selectedImage: UIImage
    @ObservedObject var detector: HumanBodyPose2DDetector
    
    @Environment(\.modelContext) private var modelContext
    
    var existingJoints: [JointPoint]? = nil
    
    
    @State private var isMenuOpen: Bool = false
    @State private var isDrawingMode: Bool = false
    @State private var isNavigateToHome: Bool = false
    
    @State private var canvasView = PKCanvasView()
    @State private var paperScale: CGFloat = 1.0
    @State private var lastPaperScale: CGFloat = 1.0
    @State private var paperOffset: CGSize = .zero
    @State private var lastPaperOffset: CGSize = .zero
    @State private var photoOffset: CGSize = .zero
    @State private var lastPhotoOffset: CGSize = .zero
    
    var body: some View {
        
        NavigationStack {
    
            ZStack(alignment: .top) {
                
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
          
                ZStack {
                    AnimeSketchSceneView(
                        selectedImage: selectedImage,
                        detector: detector,
                        savedJoints: existingJoints ?? [],
                        selectedStyle: .manga
                    )
                    
                    PencilKitCanvas(canvasView: $canvasView, isDrawingMode: $isDrawingMode)
                        .allowsHitTesting(isDrawingMode)
                }
                .aspectRatio(selectedImage.size.width > 0 ? selectedImage.size : CGSize(width: 3, height: 4), contentMode: .fit)
                .scaleEffect(paperScale)
                .offset(paperOffset)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .ignoresSafeArea(.keyboard)
                .gesture(isDrawingMode ? nil : paperTransformGesture)
                
                
   
                VStack(alignment: .leading, spacing: 20) {
                    
             
                    HStack {
             
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
//                                    if let img = exportCombinedImage() {
//                                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
//                                    }
                                    saveSketchProject()
                                    
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
                        .offset(photoOffset)
                        .gesture(photoDragGesture)
                    
                }
            }
            .onAppear {
                if let savedJoints = existingJoints, !savedJoints.isEmpty {
                    print("📸 Dashboard muncul, menggunakan \(savedJoints.count) titik AI yang tersimpan.")
                } else {
                    Task {
                        await detector.runHumanBodyPose2DRequestOnImage(uiImage: selectedImage)
                    }
                    print("📸 Dashboard muncul dengan gambar ukuran: \(selectedImage.size), menjalankan AI deteksi.")
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
            savedJoints: existingJoints ?? [],
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
    
    private func saveToFileManager(image: UIImage , fileName: String) -> URL? {
        guard let data = image.pngData() else {
            return nil
        }
        
        let paths = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )
        let documentsDirectory = paths[0]
        
        let fileUrl = documentsDirectory.appendingPathComponent("\(fileName).png")
        
        do{
            try data.write(to: fileUrl)
            return fileUrl
        }catch{
            print("File Manager error : \(error)")
            return nil
        }
        
    }
    
    
    private func saveSketchProject()  {
        let fileName = "Sketch_\(UUID().uuidString)"
        
        guard saveToFileManager(image: selectedImage, fileName: fileName) != nil else
        {
            print("Failed rendered data image")
            return
        }
        
        var jointArrays: [JointPoint] = []
        
        guard let observation = detector.humanObservation,
              let recognizePoints = try? observation.recognizedPoints(.all) else{
            print("AI data observation not found")
            return
        }
        
        
        for (jointName, point) in recognizePoints {
            if point.confidence > 0.2 {
                let newJoint = JointPoint(
                    jointName: jointName.rawValue.rawValue, coordinateX: point.location.x, coordinateY: point.location.y, depthZ: 0.0
                )
                
                jointArrays.append(newJoint)
            }
        }
        
        
        let newProject = Sketch(
            title: fileName,
            imageFileName: fileName,
            jointData: jointArrays
        )
        
        modelContext.insert(newProject)
    
        print("SAVE SUCCESS")
        printDatabaseStatusToConsole()
    }
    
    
    // MARK: - Debugging Tools
        
        private func printDatabaseStatusToConsole() {
            do {
                // 1. Create a request to fetch ALL Sketch data
                let fetchRequest = FetchDescriptor<Sketch>()
                
                // 2. Execute the fetch using our modelContext
                let allSketches = try modelContext.fetch(fetchRequest)
                
                // 3. Print the results beautifully to the Xcode Console!
                print("\n==============================================")
                print("🗄️ SWIFTDATA DATABASE STATUS")
                print("Total Saved Projects: \(allSketches.count)")
                print("----------------------------------------------")
                
                for (index, sketch) in allSketches.enumerated() {
                    print("[\(index + 1)] Title  : \(sketch.title)")
                    print("    Image  : \(sketch.imageFileName).png")
                    print("    Joints : \(sketch.jointData.count) points saved")
                    
                    // Print a sample of the first joint just to prove the data is real
                    if let firstJoint = sketch.jointData.first {
                        let formattedX = String(format: "%.2f", firstJoint.coordinateX)
                        let formattedY = String(format: "%.2f", firstJoint.coordinateY)
                        print("    Sample : \(firstJoint.jointName) is at (X: \(formattedX), Y: \(formattedY))")
                    }
                    print("----------------------------------------------")
                }
                print("==============================================\n")
                
            } catch {
                print("❌ Failed to fetch database records: \(error)")
            }
        }

    private var paperTransformGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    paperOffset = CGSize(
                        width: lastPaperOffset.width + value.translation.width,
                        height: lastPaperOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastPaperOffset = paperOffset
                },
            MagnificationGesture()
                .onChanged { value in
                    paperScale = min(max(lastPaperScale * value, 0.7), 2.5)
                }
                .onEnded { _ in
                    lastPaperScale = paperScale
                }
        )
    }

    private var photoDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                photoOffset = CGSize(
                    width: lastPhotoOffset.width + value.translation.width,
                    height: lastPhotoOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPhotoOffset = photoOffset
            }
    }
    
    
}

#Preview {
    SketchDashboardView(selectedImage: UIImage(), detector: HumanBodyPose2DDetector())
}
