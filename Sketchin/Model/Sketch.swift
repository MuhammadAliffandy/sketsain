import SwiftData
import Foundation
import CoreGraphics

struct JointPoint: Codable {
    var jointName: String
    var coordinateX: CGFloat
    var coordinateY: CGFloat
    var depthZ: Float
    var confidence: Float

    // Explicit memberwise init so callers can omit confidence and get 1.0 as default.
    init(jointName: String, coordinateX: CGFloat, coordinateY: CGFloat, depthZ: Float, confidence: Float = 1.0) {
        self.jointName = jointName
        self.coordinateX = coordinateX
        self.coordinateY = coordinateY
        self.depthZ = depthZ
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        jointName   = try c.decode(String.self, forKey: .jointName)
        coordinateX = try c.decode(CGFloat.self, forKey: .coordinateX)
        coordinateY = try c.decode(CGFloat.self, forKey: .coordinateY)
        depthZ      = try c.decode(Float.self,   forKey: .depthZ)
        confidence  = (try? c.decode(Float.self, forKey: .confidence)) ?? 1.0
    }
}

@Model
class Sketch {
    var id: UUID
    var title: String
    var imageFileName: String
    var createdAt: Date
    var jointData: [JointPoint]

    // Face bounding box stored as Vision normalized coords (0–1).
    // Optional so existing records without this data are still valid.
    var faceBBoxX: CGFloat?
    var faceBBoxY: CGFloat?
    var faceBBoxW: CGFloat?
    var faceBBoxH: CGFloat?

    /// Reconstructed face bounding box for use by the renderer.
    var savedFaceBoundingBox: CGRect? {
        guard let x = faceBBoxX, let y = faceBBoxY,
              let w = faceBBoxW, let h = faceBBoxH else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    init(
        title: String,
        imageFileName: String,
        jointData: [JointPoint] = [],
        faceBoundingBox: CGRect? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.imageFileName = imageFileName
        self.createdAt = Date()
        self.jointData = jointData
        self.faceBBoxX = faceBoundingBox?.origin.x
        self.faceBBoxY = faceBoundingBox?.origin.y
        self.faceBBoxW = faceBoundingBox?.width
        self.faceBBoxH = faceBoundingBox?.height
    }
}
