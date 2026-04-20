import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onMicTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $text)
                .textFieldStyle(.plain)

            Button(action: onMicTapped) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
