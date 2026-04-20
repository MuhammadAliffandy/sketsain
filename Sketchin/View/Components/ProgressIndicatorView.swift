import SwiftUI

struct ProgressIndicatorView: View {
    @Binding var progress: Float
    var trackColor: Color
    var progressColor: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(trackColor)

                RoundedRectangle(cornerRadius: 6)
                    .fill(progressColor)
                    .frame(width: proxy.size.width * CGFloat(progress))
            }
        }
        .frame(height: 12)
    }
}
