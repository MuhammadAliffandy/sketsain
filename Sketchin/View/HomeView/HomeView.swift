//
//  HomeView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct HomeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sketch.createdAt, order: .reverse) private var savedSketches: [Sketch]
    
    
    // --- 1. GENERAL STATES ---
    @State private var exploreSearchQuery: String = ""
    @State private var isMenuOpen: Bool = false
    @State private var isShowingGallery: Bool = false
    @State private var sketchToOpen: Sketch? = nil
    
    
    @State private var isShowingAddMenu: Bool = false
    @State private var isShowingCamera: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var navigateToTransform: Bool = false
    
    // --- 2. SELECTION MODE STATES ---
    @State private var isSelectionMode: Bool = false
    @State private var selectedItems: Set<UUID> = []
    
    // --- 3. RENAME FEATURE STATES ---
    
    
    @State private var editingSketchID: UUID? = nil
    @State private var editTitleText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let fourColumn = Array(repeating: GridItem(.flexible(), spacing: 30), count: 4)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack {
                        if isSelectionMode {
                            
                            CircleButtonView(
                                iconName: "xmark",
                                bgColor: Color(uiColor: .systemGray4),
                                tintColor: .black,
                                hasShadow: false,
                                action: {
                                    withAnimation(.spring()) {
                                        isSelectionMode = false
                                        selectedItems.removeAll()
                                    }
                                }
                            )
                            .frame(width: 45, height: 45)
                            
                        } else {
                            
                            //
                        }
                        
                        Spacer()
                        
                        if isSelectionMode {
                            let hasSelection = !selectedItems.isEmpty
                            CircleButtonView(
                                iconName: "trash",
                                bgColor: hasSelection ? Color(uiColor: .systemRed) : Color(uiColor: .systemGray4),
                                tintColor: hasSelection ? .white : .gray,
                                hasShadow: hasSelection,
                                action: {
                                    if hasSelection {
                                        // that the flow for downloading items
                                        deleteSelectedItems()
                                    }
                                }
                            )
                            .frame(width: 45, height: 45)
                            
                        } else {
                            
                            CircleButtonView(
                                iconName: "plus",
                                bgColor: Color(uiColor: .systemBlue),
                                tintColor: .white,
                                hasShadow: true,
                                action: { isShowingAddMenu = true }
                            )
                            .frame(width: 45, height: 45)
                            .confirmationDialog("Choose Source", isPresented: $isShowingAddMenu, titleVisibility: .hidden) {
                                Button("Camera") {
                                    isShowingCamera = true
                                }
                                Button("Photos") {
                                    isShowingGallery = true
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                    }
                    Text(isSelectionMode ? "\(selectedItems.count) Selected" : "Gallery")
                        .font(.system(size: 40, weight: .bold))
                    
                    
                    if !isSelectionMode {
                        SearchBarView(
                            text: $exploreSearchQuery,
                            onMicTapped: { print("Mic tapped") }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(Color(UIColor.systemGroupedBackground))
                
                ScrollView {
                    if savedSketches.isEmpty{
                        VStack(spacing: 20){
                            Spacer()
                            
                            
                            VStack(spacing: 20){
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                Text("No Sketces Yet")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                    
                                Text("Tap the + button to create your first mannequin")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                         
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                       
                    
                        
                    } else {
                        LazyVGrid(columns: fourColumn, spacing: 30) {
                            ForEach(savedSketches) { sketch in
                                SketchCardView(
                                    sketch: sketch,
                                    isSelectionMode: $isSelectionMode,
                                    selectedItems: $selectedItems,
                                    editingSketchID: $editingSketchID,
                                    editTitleText: $editTitleText,
                                    onSaveRename: {
                                        saveRenamedTitle(for: sketch)
                                    },
                                    onOpenSketch: {
                                        sketchToOpen = sketch
                                    }
                                )
                                // Move long press logic into the card struct
                            }
                        }
                        .padding(20)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $isShowingGallery, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newItem in
                if let newItem = newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    }
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    navigateToTransform = true
                }
            }
            
            .navigationDestination(item: $sketchToOpen, destination: {
                selectedSketch in

                let fileName = selectedSketch.imageFileName
                let savedImage = loadImageFromDisk(fileName: fileName) ?? UIImage()
            
                SketchDashboardView(
                    selectedImage: savedImage,
                    detector: HumanBodyPose2DDetector(),
                    existingJoints: selectedSketch.jointData
                )
            })
            
            .navigationDestination(isPresented: $navigateToTransform) {
                if let selectedImage = selectedImage {
                    LoadingView(selectedImage: selectedImage)
                }
            }
        }
    }
    
   
    private func loadImageFromDisk(fileName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent("\(fileName).png")
        return UIImage(contentsOfFile: fileURL.path)
    }
   
    
    private func deleteSelectedItems() {
            withAnimation(.spring()) {
                for sketch in savedSketches {
                    if selectedItems.contains(sketch.id) {
                        // Delete from database
                        modelContext.delete(sketch)
                        
                        // 🟢 FIX: File deletion MUST be inside the if statement
                        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        let fileURL = paths[0].appendingPathComponent("\(sketch.imageFileName).png")
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
                selectedItems.removeAll()
                isSelectionMode = false
                try? modelContext.save()
            }
        }
        
    private func saveRenamedTitle(for sketch: Sketch){
        sketch.title = editTitleText
        try? modelContext.save()
        editingSketchID = nil
    }
    
}



#Preview {
    HomeView()
}
