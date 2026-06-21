import Vision
import CoreImage

final class OCRScanner {
    func recognizeText(in pixelBuffer: CVPixelBuffer, completion: @escaping ([String]) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            let candidates = results.compactMap { $0.topCandidates(1).first?.string }
            completion(candidates)
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "fr-FR"]
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion([])
        }
    }
}
