import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onMicTapped: () -> Void
    
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
        
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isFocused ? .blue : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField("Search...", text: $text)
                .focused($isFocused)
                .font(.system(size: 18, weight: .regular))
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.spring()) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 2)

            Button(action: onMicTapped) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isFocused ? .blue : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 55)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(isFocused ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        
        .shadow(
            color: .black.opacity(isFocused ? 0.15 : 0.05),
            radius: isFocused ? 15 : 5,
            x: 0,
            y: isFocused ? 8 : 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}
