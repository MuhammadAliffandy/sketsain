import SwiftUI

struct MyiPadView: View {
    
    // 1. STATE: To control if the menu is showing or hidden
    @State private var isMenuOpen: Bool = false
    
    var body: some View {
        NavigationStack {
            
            // Your main content
            Color.gray.opacity(0.1).ignoresSafeArea()
                .navigationTitle("Dashboard")
                .toolbarBackground(Color.blue, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                
                // --- YOUR TOOLBAR SETUP ---
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        
                        // 2. YOUR BUTTON
                        Button(action: {
                            // Toggle the state when pressed
                            isMenuOpen.toggle()
                            print("Hamburger menu tapped!")
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .bold()
                        }
                        
                        // 3. THE POPOVER
                        // Attach it directly to the Button so the arrow points to it!
                        // arrowEdge: .top tells the arrow to point upwards
                        .popover(isPresented: $isMenuOpen, arrowEdge: .top) {
                            
                            // 4. THE CONTENT INSIDE THE MENU
                            VStack(alignment: .leading, spacing: 20) {
                                
                                
                                // Menu Item 1
                                Button(action: {
                                    print("Go to Sketch Area")
                                    isMenuOpen = false // Close menu after tap
                                }) {
                                    Label("Area Sketsa", systemImage: "applepencil")
                                        .foregroundColor(.primary)
                                }
                                
                                // Menu Item 2
                                Button(action: {
                                    print("Go to Gallery")
                                    isMenuOpen = false // Close menu after tap
                                }) {
                                    Label("Galeri 3D", systemImage: "photo.on.rectangle")
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(width: 350)
                            .padding()
                            // Set a nice width for iPad
                     
                            
                        } // <-- End of Popover
                        
                    }
                }
        }
    }
}


#Preview {
    MyiPadView()
}
