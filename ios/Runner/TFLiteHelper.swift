import TensorFlowLite

class TFLiteHelper {
    private var interpreter: Interpreter

    init?(modelPath: String) {
        do {
            interpreter = try Interpreter(modelPath: modelPath)
        } catch {
            print("Failed to create interpreter: \(error)")
            return nil
        }
    }

    func analyze(image: UIImage) -> Float? {
        guard let buffer = preprocess(image: image) else { return nil }

        do {
            try interpreter.copy(buffer, toInputAt: 0)
            try interpreter.invoke()
            let output = try interpreter.output(at: 0)
            return output.data.withUnsafeBytes { $0.load(as: Float.self) }
        } catch {
            print("Inference failed: \(error)")
            return nil
        }
    }

    private func preprocess(image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let width = 224
        let height = 224

        let bytesPerPixel = 4
        let imageData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: imageData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var floatData = [Float]()
        for i in 0..<width * height {
            let offset = i * bytesPerPixel
            floatData.append(Float(imageData[offset]) / 255.0)   // R
            floatData.append(Float(imageData[offset+1]) / 255.0 // G
            floatData.append(Float(imageData[offset+2]) / 255.0 // B
        }

        return floatData.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}