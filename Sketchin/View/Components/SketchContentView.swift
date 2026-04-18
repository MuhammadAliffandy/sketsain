import SwiftUI

struct SketchContent: View {
    
    let title: String  = "Untitled"
    let subtitle: String = "Default subtitle"
    
    var body: some View {
        VStack (spacing: 20){
           
            Image("img_default")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 100)
                .cornerRadius(5)
            
            VStack(spacing: 8){
                Text("\(title)")
                    .font(.system(size: 25))
                    .bold()
                
                Text("\(subtitle)")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.gray)
                    
            }
                
            
        }
    }
}

#Preview {
    SketchContent()
}
