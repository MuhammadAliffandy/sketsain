import SwiftUI

struct AnimeSketchSceneView: View {
    let selectedImage: UIImage
    @ObservedObject var detector: HumanBodyPose2DDetector

    var selectedStyle: AnimeSketchRenderer.SketchStyle = .manga
    var showSourceImage: Bool = false

    var body: some View {
        ZStack {
            Color.white

            if showSourceImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.22)
            }

            AnimeSketchRenderer(
                observation: detector.humanObservation,
                style: selectedStyle,
                limbScale: detector.bodyScale,
                limbWidthProfile: detector.limbWidthProfile,
                detectedFaceBoundingBox: detector.faceBoundingBox,
                handObservations: detector.handObservations,
                inkColor: .black
            )
            .blendMode(.multiply)
        }
        .aspectRatio(selectedImage.size.width > 0 ? selectedImage.size : CGSize(width: 3, height: 4), contentMode: .fit)
    }
}
