import SwiftUI
import Vision
import CoreImage
import CoreVideo

struct MangaSilhouetteSample {
    let contourImage: UIImage?
    let bodyScale: CGFloat
}

enum MangaSilhouetteSampler {
    static func sample(
        from segmentationObservation: VNPixelBufferObservation?,
        ciContext: CIContext
    ) -> MangaSilhouetteSample {
        guard let segmentationObservation else {
            return MangaSilhouetteSample(contourImage: nil, bodyScale: 1.0)
        }

        let pixelBuffer = segmentationObservation.pixelBuffer
        return MangaSilhouetteSample(
            contourImage: makeContourImage(from: pixelBuffer, ciContext: ciContext),
            bodyScale: computeBodyScale(from: pixelBuffer)
        )
    }

    private static func computeBodyScale(from pixelBuffer: CVPixelBuffer) -> CGFloat {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 1.0
        }

        let data = baseAddress.assumingMemoryBound(to: UInt8.self)
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var found = false

        for y in stride(from: 0, to: height, by: 2) {
            let row = data.advanced(by: y * rowBytes)
            for x in stride(from: 0, to: width, by: 2) {
                if row[x] > 18 {
                    found = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard found else {
            return 1.0
        }

        let normWidth = CGFloat(maxX - minX + 1) / CGFloat(max(width, 1))
        let normHeight = CGFloat(maxY - minY + 1) / CGFloat(max(height, 1))
        let dominant = max(normWidth, normHeight)
        return max(0.72, min(1.95, dominant / 0.64))
    }

    private static func makeContourImage(from pixelBuffer: CVPixelBuffer, ciContext: CIContext) -> UIImage? {
        let maskImage = CIImage(cvPixelBuffer: pixelBuffer)
        let edges = maskImage
            .applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: 12.0])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 12.0,
                kCIInputBrightnessKey: -0.25,
                kCIInputSaturationKey: 0.0
            ])
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 0.5])

        let ink = edges.applyingFilter(
            "CIFalseColor",
            parameters: [
                "inputColor0": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 1)
            ]
        )

        guard let cgImage = ciContext.createCGImage(ink, from: ink.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
