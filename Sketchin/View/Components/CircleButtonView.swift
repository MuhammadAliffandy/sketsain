import SwiftUI

struct CircleButtonView: View {
    var iconName: String
    var bgColor: Color
    var tintColor: Color
    var hasShadow: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(tintColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(bgColor)
        .clipShape(Circle())
        .shadow(
            color: hasShadow ? .black.opacity(0.1) : .clear,
            radius: 4,
            x: 0,
            y: 2
        )
    }
}
