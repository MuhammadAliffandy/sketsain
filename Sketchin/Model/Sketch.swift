import SwiftData
import Foundation

struct JointPoint: Codable {
    var jointName: String
    var coordinateX: CGFloat
    var coordinateY: CGFloat
    var depthZ: Float
}

@Model
class Sketch {
    var id: UUID
    var title: String
    var imageFileName: String
    var createdAt: Date

    var jointData: [JointPoint]
    
    init(title: String, imageFileName: String, jointData: [JointPoint] = []) {
        self.id = UUID()
        self.title = title
        self.imageFileName = imageFileName
        self.createdAt = Date()
        self.jointData = jointData
    }
}
