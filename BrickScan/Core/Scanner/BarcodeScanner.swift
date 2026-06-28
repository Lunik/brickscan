import Vision
import CoreImage

final class BarcodeScanner {
    private let symbologies: [VNBarcodeSymbology] = [.ean13, .ean8, .code128, .qr]

    func detectBarcode(
        in pixelBuffer: CVPixelBuffer,
        regionOfInterest: CGRect? = nil,
        completion: @escaping (String?) -> Void
    ) {
        perform(
            VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]),
            regionOfInterest: regionOfInterest,
            completion: completion
        )
    }

    func detectBarcode(in cgImage: CGImage, completion: @escaping (String?) -> Void) {
        perform(VNImageRequestHandler(cgImage: cgImage, options: [:]), regionOfInterest: nil, completion: completion)
    }

    private func perform(
        _ handler: VNImageRequestHandler,
        regionOfInterest: CGRect?,
        completion: @escaping (String?) -> Void
    ) {
        let request = VNDetectBarcodesRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNBarcodeObservation],
                  let first = results.first(where: { $0.payloadStringValue != nil }) else {
                completion(nil)
                return
            }
            completion(first.payloadStringValue)
        }
        request.symbologies = symbologies
        if let regionOfInterest {
            request.regionOfInterest = regionOfInterest
        }

        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
}
