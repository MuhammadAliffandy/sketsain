import SwiftUI
import Vision

struct AnimeSketchRenderer: View {
    enum SketchStyle: String, CaseIterable, Identifiable {
        case rough = "Rough"
        case clean = "Clean"
        case manga = "Manga"

        var id: String { rawValue }
    }

    var observation: VNHumanBodyPoseObservation?
    var style: SketchStyle = .clean
    var elongateLegsRatio: CGFloat = 1.18
    var limbScale: CGFloat = 1.0
    var limbWidthProfile: PoseLimbWidthProfile = .fallback
    var detectedFaceBoundingBox: CGRect? = nil
    var handObservations: [VNHumanHandPoseObservation] = []
    var inkColor: Color = .black

    private struct Segment {
        let a: VNHumanBodyPoseObservation.JointName
        let b: VNHumanBodyPoseObservation.JointName
        let width: CGFloat
    }

    var body: some View {
        SwiftUI.Canvas { context, size in
            guard let obs = observation else { return }
            guard let recognizedPoints = try? obs.recognizedPoints(.all) else { return }

            var mappedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

            let transformToCanvas = { (point: CGPoint) -> CGPoint in
                CGPoint(x: point.x * size.width, y: (1.0 - point.y) * size.height)
            }

            var rootCanvasY: CGFloat = size.height * 0.5
            if let root = recognizedPoints[.root], root.confidence > 0.2 {
                rootCanvasY = transformToCanvas(root.location).y
            }

            for (jointName, point) in recognizedPoints where point.confidence > 0.2 {
                var canvasPoint = transformToCanvas(point.location)
                if canvasPoint.y > rootCanvasY {
                    let diff = canvasPoint.y - rootCanvasY
                    canvasPoint.y = rootCanvasY + (diff * elongateLegsRatio)
                }
                mappedPoints[jointName] = canvasPoint
            }

            guard !mappedPoints.isEmpty else { return }

            let adaptiveScale = max(0.72, min(1.95, limbScale))
            let canvasReference = min(size.width, size.height)
            drawTorso(
                context: &context,
                points: mappedPoints,
                torsoWidthScale: limbWidthProfile.torso * canvasReference * adaptiveScale
            )
            drawJointLineArt(context: &context, points: mappedPoints)

            let segments: [Segment] = [
                Segment(a: .leftShoulder, b: .leftElbow, width: limbWidthProfile.upperArm * canvasReference * adaptiveScale),
                Segment(a: .leftElbow, b: .leftWrist, width: limbWidthProfile.lowerArm * canvasReference * adaptiveScale),
                Segment(a: .rightShoulder, b: .rightElbow, width: limbWidthProfile.upperArm * canvasReference * adaptiveScale),
                Segment(a: .rightElbow, b: .rightWrist, width: limbWidthProfile.lowerArm * canvasReference * adaptiveScale),
                Segment(a: .leftHip, b: .leftKnee, width: limbWidthProfile.upperLeg * canvasReference * adaptiveScale),
                Segment(a: .leftKnee, b: .leftAnkle, width: limbWidthProfile.lowerLeg * canvasReference * adaptiveScale),
                Segment(a: .rightHip, b: .rightKnee, width: limbWidthProfile.upperLeg * canvasReference * adaptiveScale),
                Segment(a: .rightKnee, b: .rightAnkle, width: limbWidthProfile.lowerLeg * canvasReference * adaptiveScale)
            ]

            for segment in segments {
                if style == .manga {
                    drawVolumetricLimb(context: &context, from: segment.a, to: segment.b, width: segment.width, points: mappedPoints)
                } else {
                    drawSketchLimb(context: &context, from: segment.a, to: segment.b, width: segment.width, points: mappedPoints)
                }
            }

            drawHead(context: &context, points: mappedPoints, canvasSize: size)
            drawDetectedHands(context: &context, bodyPoints: mappedPoints, canvasSize: size)
            drawHandsAndFeetHints(context: &context, points: mappedPoints)
            drawJoints(context: &context, points: mappedPoints)

            if style == .manga {
                drawJointConstruction(context: &context, points: mappedPoints)
            }
        }
    }

    private var styleOffsets: [CGFloat] {
        switch style {
        case .rough: return [-2.0, -0.8, 0.0, 0.9, 1.9]
        case .clean: return [-1.1, 0.0, 1.0]
        case .manga: return [-0.7, 0.0, 0.7]
        }
    }

    private var mainStrokeOpacity: Double {
        switch style {
        case .rough: return 0.62
        case .clean: return 0.72
        case .manga: return 0.82
        }
    }

    private var sideStrokeOpacity: Double {
        switch style {
        case .rough: return 0.22
        case .clean: return 0.28
        case .manga: return 0.18
        }
    }

    private func ink(_ opacity: Double) -> Color {
        inkColor.opacity(opacity)
    }

    private func drawJointLineArt(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        let chains: [[VNHumanBodyPoseObservation.JointName]] = [
            [.leftWrist, .leftElbow, .leftShoulder, .neck, .rightShoulder, .rightElbow, .rightWrist],
            [.leftAnkle, .leftKnee, .leftHip, .root, .rightHip, .rightKnee, .rightAnkle],
            [.neck, .root]
        ]

        let strokeWidth: CGFloat = style == .manga ? 2.0 : 1.5
        let alpha: Double = style == .manga ? 0.46 : 0.34

        for chain in chains {
            let chainPoints = chain.compactMap { points[$0] }
            guard chainPoints.count >= 2 else { continue }

            var path = Path()
            path.move(to: chainPoints[0])
            for i in 1..<chainPoints.count {
                let p0 = chainPoints[i - 1]
                let p1 = chainPoints[i]
                let mid = CGPoint(x: (p0.x + p1.x) * 0.5, y: (p0.y + p1.y) * 0.5)
                path.addQuadCurve(to: mid, control: p0)
                if i == chainPoints.count - 1 {
                    path.addQuadCurve(to: p1, control: mid)
                }
            }

            context.stroke(path, with: .color(ink(alpha)), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawSketchLimb(
        context: inout GraphicsContext,
        from: VNHumanBodyPoseObservation.JointName,
        to: VNHumanBodyPoseObservation.JointName,
        width: CGFloat,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        guard let p1 = points[from], let p2 = points[to] else { return }

        let mid = CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5)
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let len = max(sqrt(dx * dx + dy * dy), 1)
        let nx = -dy / len
        let ny = dx / len

        for offset in styleOffsets {
            let jitter = CGFloat(offset)
            var path = Path()
            path.move(to: CGPoint(x: p1.x + nx * jitter, y: p1.y + ny * jitter))
            path.addQuadCurve(
                to: CGPoint(x: p2.x - nx * jitter * 0.5, y: p2.y - ny * jitter * 0.5),
                control: CGPoint(x: mid.x + nx * jitter * 1.8, y: mid.y + ny * jitter * 1.8)
            )

            let isMain = abs(offset) < 0.001
            context.stroke(
                path,
                with: .color(ink(isMain ? mainStrokeOpacity : sideStrokeOpacity)),
                style: StrokeStyle(lineWidth: width + (isMain ? 0 : 0.8), lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawVolumetricLimb(
        context: inout GraphicsContext,
        from: VNHumanBodyPoseObservation.JointName,
        to: VNHumanBodyPoseObservation.JointName,
        width: CGFloat,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        guard let p1 = points[from], let p2 = points[to] else { return }

        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let length = max(sqrt(dx * dx + dy * dy), 1)

        let ux = dx / length
        let uy = dy / length
        let nx = -dy / length
        let ny = dx / length

        let isUpperLeg = from == .leftHip || from == .rightHip
        let isLowerLeg = from == .leftKnee || from == .rightKnee
        let isUpperArm = from == .leftShoulder || from == .rightShoulder

        let startRadius: CGFloat
        let endRadius: CGFloat
        if isUpperLeg {
            startRadius = width * 2.1
            endRadius = width * 1.55
        } else if isLowerLeg {
            startRadius = width * 1.8
            endRadius = width * 1.35
        } else if isUpperArm {
            startRadius = width * 1.7
            endRadius = width * 1.3
        } else {
            startRadius = width * 1.45
            endRadius = width * 1.12
        }

        // Leave visible joint spacing before and after limb.
        let startGap = startRadius * (style == .manga ? 0.72 : 0.58)
        let endGap = endRadius * (style == .manga ? 0.72 : 0.58)
        let adjP1 = CGPoint(x: p1.x + ux * startGap, y: p1.y + uy * startGap)
        let adjP2 = CGPoint(x: p2.x - ux * endGap, y: p2.y - uy * endGap)

        let a = CGPoint(x: adjP1.x + nx * startRadius, y: adjP1.y + ny * startRadius)
        let b = CGPoint(x: adjP2.x + nx * endRadius, y: adjP2.y + ny * endRadius)
        let c = CGPoint(x: adjP2.x - nx * endRadius, y: adjP2.y - ny * endRadius)
        let d = CGPoint(x: adjP1.x - nx * startRadius, y: adjP1.y - ny * startRadius)

        let cornerPull: CGFloat = max(startRadius, endRadius) * 0.36

        // Filled limb volume.
        var volumePath = Path()
        volumePath.move(to: a)
        volumePath.addQuadCurve(
            to: b,
            control: CGPoint(x: (a.x + b.x) * 0.5 + nx * cornerPull, y: (a.y + b.y) * 0.5 + ny * cornerPull)
        )
        volumePath.addLine(to: c)
        volumePath.addQuadCurve(
            to: d,
            control: CGPoint(x: (c.x + d.x) * 0.5 - nx * cornerPull, y: (c.y + d.y) * 0.5 - ny * cornerPull)
        )
        volumePath.closeSubpath()

        context.fill(volumePath, with: .color(ink(0.07)))
        context.stroke(volumePath, with: .color(ink(0.82)), lineWidth: 1.6)

        // Two contour side-lines so the width follows the limb corners like line art.
        var side1 = Path()
        side1.move(to: a)
        side1.addQuadCurve(
            to: b,
            control: CGPoint(x: (a.x + b.x) * 0.5 + nx * cornerPull * 1.15, y: (a.y + b.y) * 0.5 + ny * cornerPull * 1.15)
        )
        context.stroke(side1, with: .color(ink(0.88)), lineWidth: 1.9)

        var side2 = Path()
        side2.move(to: d)
        side2.addQuadCurve(
            to: c,
            control: CGPoint(x: (d.x + c.x) * 0.5 - nx * cornerPull * 1.15, y: (d.y + c.y) * 0.5 - ny * cornerPull * 1.15)
        )
        context.stroke(side2, with: .color(ink(0.88)), lineWidth: 1.9)

        // Light cap hints at both ends.
        let startEllipse = CGRect(x: adjP1.x - startRadius * 0.82, y: adjP1.y - startRadius * 0.42, width: startRadius * 1.64, height: startRadius * 0.84)
        let endEllipse = CGRect(x: adjP2.x - endRadius * 0.82, y: adjP2.y - endRadius * 0.42, width: endRadius * 1.64, height: endRadius * 0.84)
        context.stroke(Path(ellipseIn: startEllipse), with: .color(ink(0.24)), lineWidth: 0.9)
        context.stroke(Path(ellipseIn: endEllipse), with: .color(ink(0.24)), lineWidth: 0.9)

        var centerLine = Path()
        centerLine.move(to: adjP1)
        centerLine.addQuadCurve(
            to: adjP2,
            control: CGPoint(x: (adjP1.x + adjP2.x) * 0.5 + nx * 1.4, y: (adjP1.y + adjP2.y) * 0.5 + ny * 1.4)
        )
        context.stroke(centerLine, with: .color(ink(0.22)), lineWidth: 0.9)
    }

    private func drawTorso(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint],
        torsoWidthScale: CGFloat
    ) {
        guard
            let leftShoulder = points[.leftShoulder],
            let rightShoulder = points[.rightShoulder],
            let leftHip = points[.leftHip],
            let rightHip = points[.rightHip]
        else { return }

        let shoulderInset = max(6, torsoWidthScale * 0.12)
        let hipInset = max(8, torsoWidthScale * 0.15)

        if style == .manga {
            let topCenter = CGPoint(x: (leftShoulder.x + rightShoulder.x) * 0.5, y: (leftShoulder.y + rightShoulder.y) * 0.5)
            let bottomCenter = CGPoint(x: (leftHip.x + rightHip.x) * 0.5, y: (leftHip.y + rightHip.y) * 0.5)

            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: leftShoulder.x + shoulderInset, y: leftShoulder.y + 2))
            bodyPath.addQuadCurve(to: CGPoint(x: leftHip.x + hipInset, y: leftHip.y - 2), control: CGPoint(x: leftShoulder.x - torsoWidthScale * 0.34, y: bottomCenter.y - torsoWidthScale * 0.52))
            bodyPath.addQuadCurve(to: CGPoint(x: rightHip.x - hipInset, y: rightHip.y - 2), control: CGPoint(x: bottomCenter.x, y: bottomCenter.y + torsoWidthScale * 0.18))
            bodyPath.addQuadCurve(to: CGPoint(x: rightShoulder.x - shoulderInset, y: rightShoulder.y + 2), control: CGPoint(x: rightShoulder.x + torsoWidthScale * 0.34, y: bottomCenter.y - torsoWidthScale * 0.52))
            bodyPath.addQuadCurve(to: CGPoint(x: leftShoulder.x + shoulderInset, y: leftShoulder.y + 2), control: CGPoint(x: topCenter.x, y: topCenter.y - torsoWidthScale * 0.16))

            context.fill(bodyPath, with: .color(Color.black.opacity(0.05)))
            context.stroke(bodyPath, with: .color(.black.opacity(0.82)), lineWidth: 2.2)

            var centerLine = Path()
            centerLine.move(to: topCenter)
            centerLine.addQuadCurve(to: bottomCenter, control: CGPoint(x: topCenter.x - 8, y: bottomCenter.y - 26))
            context.stroke(centerLine, with: .color(.black.opacity(0.26)), lineWidth: 1.2)

            if let neck = points[.neck] {
                var neckLine = Path()
                neckLine.move(to: neck)
                neckLine.addLine(to: topCenter)
                context.stroke(neckLine, with: .color(.black.opacity(0.3)), lineWidth: 1.2)
            }
            return
        }

        var torsoPath = Path()
        torsoPath.move(to: CGPoint(x: leftShoulder.x + shoulderInset, y: leftShoulder.y + 2))
        torsoPath.addLine(to: CGPoint(x: rightShoulder.x - shoulderInset, y: rightShoulder.y + 2))
        torsoPath.addLine(to: CGPoint(x: rightHip.x - hipInset, y: rightHip.y - 2))
        torsoPath.addLine(to: CGPoint(x: leftHip.x + hipInset, y: leftHip.y - 2))
        torsoPath.closeSubpath()

        context.fill(torsoPath, with: .color(Color.black.opacity(style == .rough ? 0.16 : 0.2)))
        context.stroke(torsoPath, with: .color(.black.opacity(0.72)), lineWidth: 2.0)
    }


    private func drawHead(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint],
        canvasSize: CGSize
    ) {
        guard let neck = points[.neck] else { return }

        let leftShoulder = points[.leftShoulder]
        let rightShoulder = points[.rightShoulder]
        let shoulderWidth = (leftShoulder != nil && rightShoulder != nil)
            ? hypot((leftShoulder!.x - rightShoulder!.x), (leftShoulder!.y - rightShoulder!.y))
            : CGFloat(90)

        let nose = points[.nose]
        let leftEye = points[.leftEye]
        let rightEye = points[.rightEye]
        let leftEar = points[.leftEar]
        let rightEar = points[.rightEar]

        var widthCandidates: [CGFloat] = []

        if let lEye = leftEye, let rEye = rightEye {
            widthCandidates.append(hypot(lEye.x - rEye.x, lEye.y - rEye.y) * 1.62)
        }

        if let lEar = leftEar, let rEar = rightEar {
            widthCandidates.append(hypot(lEar.x - rEar.x, lEar.y - rEar.y) * 0.98)
        }

        widthCandidates.append(shoulderWidth * 0.40)

        var detectedFaceWidth: CGFloat?
        var faceRectFromDetection: CGRect?
        if let faceBox = detectedFaceBoundingBox {
            let width = faceBox.width * canvasSize.width
            let height = faceBox.height * canvasSize.height
            let x = faceBox.origin.x * canvasSize.width
            let y = (1.0 - faceBox.origin.y - faceBox.height) * canvasSize.height
            faceRectFromDetection = CGRect(x: x, y: y, width: width, height: height)
            detectedFaceWidth = width
        }

        let rawWidth = widthCandidates.reduce(0, +) / CGFloat(max(widthCandidates.count, 1))
        let minWidth = shoulderWidth * 0.20
        let maxWidth = shoulderWidth * 0.54

        let headDiameter: CGFloat
        if let faceWidth = detectedFaceWidth {
            // Prioritize face detection for stable head proportion.
            headDiameter = max(minWidth, min(maxWidth, faceWidth * 1.04))
        } else {
            let poseBasedWidth = max(minWidth, min(maxWidth, rawWidth))
            let neckToNose = nose.map { hypot(neck.x - $0.x, neck.y - $0.y) } ?? (poseBasedWidth * 0.30)
            headDiameter = max(minWidth, min(maxWidth, max(poseBasedWidth, neckToNose * 1.45)))
        }

        let center: CGPoint
        if let faceRect = faceRectFromDetection {
            center = CGPoint(x: faceRect.midX, y: faceRect.midY)
        } else if let lEye = leftEye, let rEye = rightEye {
            let eyeCenter = CGPoint(x: (lEye.x + rEye.x) * 0.5, y: (lEye.y + rEye.y) * 0.5)
            center = CGPoint(x: eyeCenter.x, y: eyeCenter.y - headDiameter * 0.14)
        } else if let n = nose {
            center = CGPoint(x: n.x, y: n.y - headDiameter * 0.18)
        } else {
            center = CGPoint(x: neck.x, y: neck.y - headDiameter * 0.40)
        }

        let rect = CGRect(
            x: center.x - headDiameter * 0.5,
            y: center.y - headDiameter * 0.5,
            width: headDiameter,
            height: headDiameter
        )

        let path = Path(ellipseIn: rect)
        context.fill(path, with: .color(Color.black.opacity(style == .manga ? 0.05 : 0.12)))
        context.stroke(path, with: .color(.black.opacity(style == .manga ? 0.9 : 0.86)), lineWidth: style == .manga ? 2.2 : 1.9)

        // Head center guide (optional sketch axis)
        if style == .manga {
            var vGuide = Path()
            vGuide.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.08))
            vGuide.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.08))
            context.stroke(vGuide, with: .color(.black.opacity(0.45)), lineWidth: 1.0)
        }

        // Neck line connection from head base to shoulders.
        if let leftShoulder = leftShoulder, let rightShoulder = rightShoulder {
            let neckHalfWidth = max(4, shoulderWidth * 0.08)
            let neckBaseY = rect.maxY - (headDiameter * 0.03)

            var leftNeck = Path()
            leftNeck.move(to: CGPoint(x: rect.midX - neckHalfWidth, y: neckBaseY))
            leftNeck.addLine(to: CGPoint(x: leftShoulder.x + shoulderWidth * 0.10, y: leftShoulder.y))
            context.stroke(leftNeck, with: .color(.black.opacity(style == .manga ? 0.62 : 0.48)), lineWidth: 1.25)

            var rightNeck = Path()
            rightNeck.move(to: CGPoint(x: rect.midX + neckHalfWidth, y: neckBaseY))
            rightNeck.addLine(to: CGPoint(x: rightShoulder.x - shoulderWidth * 0.10, y: rightShoulder.y))
            context.stroke(rightNeck, with: .color(.black.opacity(style == .manga ? 0.62 : 0.48)), lineWidth: 1.25)
        }
    }

    private func canvasPoint(from normalizedPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        CGPoint(x: normalizedPoint.x * canvasSize.width, y: (1.0 - normalizedPoint.y) * canvasSize.height)
    }

    private func handPoint(
        _ name: VNHumanHandPoseObservation.JointName,
        from points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint],
        canvasSize: CGSize
    ) -> CGPoint? {
        guard let point = points[name], point.confidence > 0.24 else { return nil }
        return canvasPoint(from: point.location, canvasSize: canvasSize)
    }

    private func drawDetectedHands(
        context: inout GraphicsContext,
        bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        canvasSize: CGSize
    ) {
        guard !handObservations.isEmpty else { return }

        let fingerChains: [[VNHumanHandPoseObservation.JointName]] = [
            [.thumbCMC, .thumbMP, .thumbIP, .thumbTip],
            [.indexMCP, .indexPIP, .indexDIP, .indexTip],
            [.middleMCP, .middlePIP, .middleDIP, .middleTip],
            [.ringMCP, .ringPIP, .ringDIP, .ringTip],
            [.littleMCP, .littlePIP, .littleDIP, .littleTip]
        ]

        for hand in handObservations {
            guard let points = try? hand.recognizedPoints(.all) else { continue }
            guard let wrist = handPoint(.wrist, from: points, canvasSize: canvasSize) else { continue }

            // Connect detected hand to the nearest body wrist/elbow so the hand reads as attached.
            let leftWrist = bodyPoints[.leftWrist]
            let rightWrist = bodyPoints[.rightWrist]
            let connectLeft = (leftWrist != nil) ? hypot(leftWrist!.x - wrist.x, leftWrist!.y - wrist.y) : .greatestFiniteMagnitude
            let connectRight = (rightWrist != nil) ? hypot(rightWrist!.x - wrist.x, rightWrist!.y - wrist.y) : .greatestFiniteMagnitude

            let useLeft = connectLeft <= connectRight
            let bodyWrist = useLeft ? leftWrist : rightWrist
            let bodyElbow = useLeft ? bodyPoints[.leftElbow] : bodyPoints[.rightElbow]

            if let bodyWrist {
                var bridge = Path()
                if let bodyElbow {
                    bridge.move(to: bodyElbow)
                    bridge.addQuadCurve(
                        to: wrist,
                        control: CGPoint(x: (bodyElbow.x + bodyWrist.x) * 0.5, y: (bodyElbow.y + bodyWrist.y) * 0.5)
                    )
                } else {
                    bridge.move(to: bodyWrist)
                    bridge.addLine(to: wrist)
                }
                context.stroke(
                    bridge,
                    with: .color(.black.opacity(style == .manga ? 0.88 : 0.78)),
                    style: StrokeStyle(lineWidth: style == .manga ? 2.0 : 1.5, lineCap: .round, lineJoin: .round)
                )
            }

            let palmNames: [VNHumanHandPoseObservation.JointName] = [.indexMCP, .middleMCP, .ringMCP, .littleMCP]
            let palmPoints = palmNames.compactMap { handPoint($0, from: points, canvasSize: canvasSize) }

            if palmPoints.count >= 3 {
                var palm = Path()
                palm.move(to: wrist)
                for p in palmPoints {
                    palm.addLine(to: p)
                }
                palm.closeSubpath()
                context.fill(palm, with: .color(Color.black.opacity(style == .manga ? 0.08 : 0.05)))
                context.stroke(palm, with: .color(.black.opacity(0.82)), lineWidth: style == .manga ? 1.6 : 1.2)
            }

            for chain in fingerChains {
                let fingerPoints = chain.compactMap { handPoint($0, from: points, canvasSize: canvasSize) }
                guard fingerPoints.count >= 2 else { continue }

                var path = Path()
                path.move(to: wrist)
                path.addLine(to: fingerPoints[0])
                for i in 1..<fingerPoints.count {
                    path.addLine(to: fingerPoints[i])
                }

                context.stroke(path, with: .color(.black.opacity(0.86)), style: StrokeStyle(lineWidth: style == .manga ? 1.6 : 1.2, lineCap: .round, lineJoin: .round))

                for (idx, point) in fingerPoints.enumerated() {
                    let radius = idx == fingerPoints.count - 1 ? 1.4 : 1.8
                    let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.62)))
                }
            }
        }
    }

    private func drawHandsAndFeetHints(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        // Keep wrist hints only when hand landmarks are unavailable.
        if handObservations.isEmpty {
            for joint in [VNHumanBodyPoseObservation.JointName.leftWrist, .rightWrist] {
                guard let point = points[joint] else { continue }
                let rect = CGRect(x: point.x - 6, y: point.y - 5, width: 12, height: 10)
                context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.72)), lineWidth: 1.5)
            }
        }

        // Feet are oriented from knee->ankle direction to improve kick/action sketch readability.
        let legs: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.leftKnee, .leftAnkle),
            (.rightKnee, .rightAnkle)
        ]

        for (kneeJoint, ankleJoint) in legs {
            guard let knee = points[kneeJoint], let ankle = points[ankleJoint] else { continue }

            let dx = ankle.x - knee.x
            let dy = ankle.y - knee.y
            let length = max(hypot(dx, dy), 1)
            let ux = dx / length
            let uy = dy / length
            let nx = -uy
            let ny = ux

            let footLength: CGFloat = max(15, min(42, length * 0.55))
            let heelWidth: CGFloat = footLength * 0.34
            let toeWidth: CGFloat = footLength * 0.54

            let heelCenter = CGPoint(x: ankle.x - ux * footLength * 0.12, y: ankle.y - uy * footLength * 0.12)
            let toeCenter = CGPoint(x: ankle.x + ux * footLength * 0.88, y: ankle.y + uy * footLength * 0.88)

            let h1 = CGPoint(x: heelCenter.x + nx * heelWidth * 0.5, y: heelCenter.y + ny * heelWidth * 0.5)
            let h2 = CGPoint(x: heelCenter.x - nx * heelWidth * 0.5, y: heelCenter.y - ny * heelWidth * 0.5)
            let t1 = CGPoint(x: toeCenter.x + nx * toeWidth * 0.5, y: toeCenter.y + ny * toeWidth * 0.5)
            let t2 = CGPoint(x: toeCenter.x - nx * toeWidth * 0.5, y: toeCenter.y - ny * toeWidth * 0.5)

            var foot = Path()
            foot.move(to: h1)
            foot.addLine(to: t1)
            foot.addLine(to: t2)
            foot.addLine(to: h2)
            foot.closeSubpath()

            context.fill(foot, with: .color(Color.black.opacity(0.06)))
            context.stroke(foot, with: .color(.black.opacity(0.78)), lineWidth: 1.5)
        }
    }

    private func drawJoints(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        if style == .manga { return }

        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee
        ]

        for joint in joints {
            guard let point = points[joint] else { continue }
            let radius: CGFloat = (joint == .leftHip || joint == .rightHip) ? 4.8 : 4.0
            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            let path = Path(ellipseIn: rect)
            context.fill(path, with: .color(.white.opacity(0.45)))
            context.stroke(path, with: .color(.black.opacity(0.56)), lineWidth: 1.2)
        }
    }

    private func drawJointConstruction(
        context: inout GraphicsContext,
        points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        let major: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
        ]

        for joint in major {
            guard let point = points[joint] else { continue }

            let radius: CGFloat
            switch joint {
            case .leftHip, .rightHip:
                radius = 9.8
            case .leftKnee, .rightKnee, .leftShoulder, .rightShoulder:
                radius = 8.3
            default:
                radius = 6.6
            }

            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.84)), lineWidth: 1.25)
        }
    }
}
