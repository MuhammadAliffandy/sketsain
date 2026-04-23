import SwiftUI


struct SketchCardView: View {
    let sketch: Sketch
    
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var editingSketchID: UUID?
    @Binding var editTitleText: String
    
    var onSaveRename: () -> Void
    var onOpenSketch: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var cachedImage: UIImage? = nil
    
    var body: some View {
        let isSelected = selectedItems.contains(sketch.id)
        
        ZStack {
            VStack {
                // 1. Image Section (Read from RAM, not Disk)
                if let loadedImage = cachedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1 , contentMode: .fit)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(10)
                }
                
                // 2. Title Section
                if editingSketchID == sketch.id {
                    TextField("Enter Title", text: $editTitleText)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(4)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            onSaveRename()
                        }
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .onAppear { isTextFieldFocused = true }
                } else {
                    Text(sketch.title)
                        .font(.headline)
                        .onTapGesture(count: 2) {
                            if !isSelectionMode {
                                editingSketchID = sketch.id
                                editTitleText = sketch.title
                            }
                        }
                }
                
                // 3. Subtitle
                Text(sketch.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .opacity(isSelectionMode && !isSelected ? 0.6 : 1.0)
            
            // 4. Selection Overlay
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(isSelected ? .blue : .white)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
            }
        }
        // Interaction Logic
        .onTapGesture(count: 1) {
            if editingSketchID != nil {
                onSaveRename()
            } else if isSelectionMode {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if isSelected {
                        selectedItems.remove(sketch.id)
                    } else {
                        selectedItems.insert(sketch.id)
                    }
                }
            } else {
                onOpenSketch()
            }
        }
        .onLongPressGesture {
            guard !isSelectionMode, editingSketchID == nil else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSelectionMode = true
                selectedItems = [sketch.id]
            }
        }
        // Load image only ONCE when the card appears
        .onAppear {
            if cachedImage == nil {
                cachedImage = loadImageFromDisk(fileName: sketch.imageFileName)
            }
        }
    }
    
    private func loadImageFromDisk(fileName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory , in : .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("\(fileName).png")
        return UIImage(contentsOfFile: fileUrl.path)
    }
}
//#Preview {
//    SketchCardView()
//}
