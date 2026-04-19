import Foundation
import Vision
import SwiftUI
import Combine
import CoreImage

enum MangaBodyStyle: String, CaseIterable, Identifiable {
    case slim = "Slim"
    case balanced = "Balanced"
    case strong = "Strong"

    var id: String { rawValue }

    var widthMultiplier: CGFloat {
        switch self {
        case .slim:
            return 0.92
        case .balanced:
            return 1.0
        case .strong:
            return 1.12
        }
    }

    var torsoMultiplier: CGFloat {
        switch self {
        case .slim:
            return 0.90
        case .balanced:
            return 1.0
        case .strong:
            return 1.16
        }
    }
}

struct PoseLimbWidthProfile {
    let upperArm: CGFloat
    let lowerArm: CGFloat
    let upperLeg: CGFloat
    let lowerLeg: CGFloat
    let torso: CGFloat

    static let fallback = PoseLimbWidthProfile(
        upperArm: 0.023,
        lowerArm: 0.018,
        upperLeg: 0.033,
        lowerLeg: 0.026,
        torso: 0.138
    )
}

final class HumanBodyPose2DDetector: NSObject, ObservableObject {

    @Published var humanObservation: VNHumanBodyPoseObservation? = nil
    @Published var bodyScale: CGFloat = 1.0
    @Published var faceBoundingBox: CGRect? = nil
    @Published var handObservations: [VNHumanHandPoseObservation] = []
    @Published var limbWidthProfile: PoseLimbWidthProfile = .fallback
    @Published var segmentationLineArt: UIImage? = nil

    var mangaBodyStyle: MangaBodyStyle = .slim
    private let ciContext = CIContext()

    // MARK: - Create and run requests on the image.
    public func runHumanBodyPose2DRequestOnImage(uiImage: UIImage) async {
        guard let cgImage = uiImage.cgImage else {
            await MainActor.run {
                resetDetections()
            }
            return
        }

        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        await performRequests(with: requestHandler)
    }

    public func runHumanBodyPose2DRequestOnImage(fileURL: URL?) async {
        guard let fileURL else {
            await MainActor.run {
                resetDetections()
            }
            return
        }

        let requestHandler = VNImageRequestHandler(url: fileURL, options: [:])
        await performRequests(with: requestHandler)
    }

    private func performRequests(with requestHandler: VNImageRequestHandler) async {
        let poseRequest = VNDetectHumanBodyPoseRequest()
        poseRequest.revision = VNDetectHumanBodyPoseRequest.currentRevision

        let segmentationRequest = VNGeneratePersonSegmentationRequest()
        segmentationRequest.qualityLevel = .accurate
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let faceRequest = VNDetectFaceRectanglesRequest()

        let handRequest = VNDetectHumanHandPoseRequest()
        handRequest.maximumHandCount = 2
        handRequest.revision = VNDetectHumanHandPoseRequest.currentRevision

        do {
            try requestHandler.perform([poseRequest, segmentationRequest, faceRequest, handRequest])
        } catch {
            print("Unable to perform the 2D requests: \(error).")
            await MainActor.run {
                resetDetections()
            }
            return
        }

        let poseObservation = poseRequest.results?.first
        let faceObservation = faceRequest.results?.first
        let handObservations = handRequest.results ?? []
        let computedScale = computeBodyScale(poseObservation: poseObservation)
        let limbWidthProfile = computeLimbWidthProfile(
            poseObservation: poseObservation,
            bodyStyle: mangaBodyStyle
        )
        let silhouetteSample = MangaSilhouetteSampler.sample(
            from: segmentationRequest.results?.first,
            ciContext: ciContext
        )

        await MainActor.run {
            self.humanObservation = poseObservation
            self.bodyScale = computedScale
            self.faceBoundingBox = faceObservation?.boundingBox
            self.handObservations = handObservations
            self.limbWidthProfile = limbWidthProfile
            self.segmentationLineArt = silhouetteSample.contourImage
        }
    }

    private func computeBodyScale(poseObservation: VNHumanBodyPoseObservation?) -> CGFloat {
        var poseScale: CGFloat = 1.0
        if let poseObservation,
           let points = try? poseObservation.recognizedPoints(.all),
           let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.2,
           let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.2,
           let leftHip = points[.leftHip], leftHip.confidence > 0.2,
           let rightHip = points[.rightHip], rightHip.confidence > 0.2 {
            let shoulderWidth = hypot(
                leftShoulder.location.x - rightShoulder.location.x,
                leftShoulder.location.y - rightShoulder.location.y
            )
            let hipWidth = hypot(
                leftHip.location.x - rightHip.location.x,
                leftHip.location.y - rightHip.location.y
            )
            let bodyWidth = max((shoulderWidth + hipWidth) * 0.5, 0.001)
            poseScale = max(0.72, min(1.95, CGFloat(bodyWidth / 0.23)))
        }

        return poseScale
    }

    func updateBodyStyle(_ bodyStyle: MangaBodyStyle, for poseObservation: VNHumanBodyPoseObservation? = nil) {
        mangaBodyStyle = bodyStyle
        let sourceObservation = poseObservation ?? humanObservation
        limbWidthProfile = computeLimbWidthProfile(
            poseObservation: sourceObservation,
            bodyStyle: bodyStyle
        )
    }

    private func computeLimbWidthProfile(
        poseObservation: VNHumanBodyPoseObservation?,
        bodyStyle: MangaBodyStyle
    ) -> PoseLimbWidthProfile {
        guard let poseObservation,
              let points = try? poseObservation.recognizedPoints(.all) else {
            return .fallback
        }

        let shoulderSpan = averageDistance(points, pairs: [(.leftShoulder, .rightShoulder)])
        let hipSpan = averageDistance(points, pairs: [(.leftHip, .rightHip)])
        let torsoHeight = averageDistance(
            points,
            pairs: [(.leftShoulder, .leftHip), (.rightShoulder, .rightHip)]
        )
        let upperArmLength = averageDistance(
            points,
            pairs: [(.leftShoulder, .leftElbow), (.rightShoulder, .rightElbow)]
        )
        let lowerArmLength = averageDistance(
            points,
            pairs: [(.leftElbow, .leftWrist), (.rightElbow, .rightWrist)]
        )
        let upperLegLength = averageDistance(
            points,
            pairs: [(.leftHip, .leftKnee), (.rightHip, .rightKnee)]
        )
        let lowerLegLength = averageDistance(
            points,
            pairs: [(.leftKnee, .leftAnkle), (.rightKnee, .rightAnkle)]
        )

        let frameWidth = max((shoulderSpan * 0.58) + (hipSpan * 0.42), 0.001)
        let torsoMass = max((torsoHeight * 0.55) + (frameWidth * 0.45), 0.001)

        let baseProfile = PoseLimbWidthProfile(
            upperArm: clamp((frameWidth * 0.084) + (upperArmLength * 0.038), min: 0.013, max: 0.041),
            lowerArm: clamp((frameWidth * 0.066) + (lowerArmLength * 0.028), min: 0.011, max: 0.034),
            upperLeg: clamp((hipSpan * 0.134) + (upperLegLength * 0.062) + (torsoMass * 0.010), min: 0.019, max: 0.056),
            lowerLeg: clamp((hipSpan * 0.098) + (lowerLegLength * 0.039), min: 0.015, max: 0.045),
            torso: clamp((frameWidth * 0.540) + (torsoHeight * 0.190), min: 0.084, max: 0.210)
        )

        return adjustedProfile(baseProfile, for: bodyStyle)
    }

    private func adjustedProfile(
        _ profile: PoseLimbWidthProfile,
        for bodyStyle: MangaBodyStyle
    ) -> PoseLimbWidthProfile {
        PoseLimbWidthProfile(
            upperArm: clamp(profile.upperArm * bodyStyle.widthMultiplier, min: 0.011, max: 0.046),
            lowerArm: clamp(profile.lowerArm * bodyStyle.widthMultiplier, min: 0.010, max: 0.038),
            upperLeg: clamp(profile.upperLeg * bodyStyle.widthMultiplier, min: 0.017, max: 0.062),
            lowerLeg: clamp(profile.lowerLeg * bodyStyle.widthMultiplier, min: 0.013, max: 0.050),
            torso: clamp(profile.torso * bodyStyle.torsoMultiplier, min: 0.078, max: 0.235)
        )
    }

    private func averageDistance(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        pairs: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)]
    ) -> CGFloat {
        let distances = pairs.compactMap { a, b -> CGFloat? in
            guard let pointA = points[a], pointA.confidence > 0.2,
                  let pointB = points[b], pointB.confidence > 0.2 else {
                return nil
            }

            return hypot(
                pointA.location.x - pointB.location.x,
                pointA.location.y - pointB.location.y
            )
        }

        guard !distances.isEmpty else {
            return 0
        }

        return distances.reduce(CGFloat.zero, +) / CGFloat(distances.count)
    }

    private func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        Swift.max(lower, Swift.min(upper, value))
    }

    private func resetDetections() {
        humanObservation = nil
        bodyScale = 1.0
        faceBoundingBox = nil
        handObservations = []
        limbWidthProfile = .fallback
        segmentationLineArt = nil
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .down: self = .down
            case .left: self = .left
            case .right: self = .right
            case .upMirrored: self = .upMirrored
            case .downMirrored: self = .downMirrored
            case .leftMirrored: self = .leftMirrored
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}
