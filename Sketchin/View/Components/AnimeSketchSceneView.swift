import SwiftUI

struct AnimeSketchSceneView: View {
    let selectedImage: UIImage
    @ObservedObject var detector: HumanBodyPose2DDetector
    var savedJoints: [JointPoint] = []
    var savedFaceBoundingBox: CGRect? = nil
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
                savedJoints: savedJoints,
                style: selectedStyle,
                limbScale: detector.bodyScale,
                limbWidthProfile: detector.limbWidthProfile,
                // Live face bbox takes priority; fall back to saved bbox for reopened sketches.
                detectedFaceBoundingBox: detector.faceBoundingBox ?? savedFaceBoundingBox,
                handObservations: detector.handObservations
            )
            .blendMode(.multiply)
        }
        .aspectRatio(selectedImage.size.width > 0 ? selectedImage.size : CGSize(width: 3, height: 4), contentMode: .fit)
    }
}
