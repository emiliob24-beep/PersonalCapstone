//
//  ReceiptScanner.swift
//  PersonalCapstone
//

import SwiftUI
import VisionKit
import Vision

struct ReceiptScanResult {
    var imageData: Data
    var cost: Double?
    var date: Date?
    var mileage: Int32?
    var shop: String?
}

struct ReceiptScanner: UIViewControllerRepresentable {

    var onScan: (ReceiptScanResult) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (ReceiptScanResult) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping (ReceiptScanResult) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            let image = scan.imageOfPage(at: 0)
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                onCancel()
                return
            }

            ReceiptTextParser.recognizeText(in: image) { lines in
                let parsed = ReceiptTextParser.parse(lines)
                self.onScan(ReceiptScanResult(
                    imageData: imageData,
                    cost: parsed.cost,
                    date: parsed.date,
                    mileage: parsed.mileage,
                    shop: parsed.shop
                ))
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Receipt scan failed: \(error)")
            onCancel()
        }
    }
}

// MARK: - OCR + heuristic field extraction

enum ReceiptTextParser {

    static func recognizeText(in image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(lines)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Best-effort guesses only — a receipt's layout varies a lot, so every
    /// field here is meant to prefill a form the user still reviews, not to
    /// be authoritative.
    static func parse(_ lines: [String]) -> (cost: Double?, date: Date?, mileage: Int32?, shop: String?) {
        (cost: guessCost(lines), date: guessDate(lines), mileage: guessMileage(lines), shop: guessShop(lines))
    }

    private static func guessCost(_ lines: [String]) -> Double? {
        let currencyPattern = /\$?\s?(\d{1,5}\.\d{2})/

        // Prefer a line mentioning "total" — otherwise fall back to the
        // largest dollar amount found anywhere, which is usually the total
        // on a receipt with subtotal/tax/total all listed.
        for line in lines where line.localizedCaseInsensitiveContains("total") {
            if let match = line.firstMatch(of: currencyPattern), let value = Double(match.1) {
                return value
            }
        }

        let allAmounts = lines.compactMap { line in
            line.firstMatch(of: currencyPattern).flatMap { Double($0.1) }
        }
        return allAmounts.max()
    }

    private static func guessDate(_ lines: [String]) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        for line in lines {
            guard let detector else { break }
            let range = NSRange(line.startIndex..., in: line)
            if let match = detector.firstMatch(in: line, range: range), let date = match.date {
                return date
            }
        }
        return nil
    }

    private static func guessMileage(_ lines: [String]) -> Int32? {
        let numberThenLabel = /(\d{1,3}(?:,\d{3})+|\d{4,7})\s*(?:mi\b|miles|mileage|odometer)/.ignoresCase()

        // "Mileage:" / "Odometer" before the number is at least as common as
        // the reverse — deliberately excludes bare "mi" here since that also
        // matches the "MI" state abbreviation in an address/zip line.
        let labelThenNumber = /(?:mileage|odometer|miles)\s*(?:in)?[:\-]?\s*(\d{1,3}(?:,\d{3})+|\d{4,7})/.ignoresCase()

        for pattern in [numberThenLabel, labelThenNumber] {
            for line in lines {
                if let match = line.firstMatch(of: pattern) {
                    let digits = match.1.replacing(",", with: "")
                    if let value = Int32(digits) {
                        return value
                    }
                }
            }
        }
        return nil
    }

    private static func guessShop(_ lines: [String]) -> String? {
        // The business name is almost always one of the first couple of
        // lines on a receipt, before the address/phone number block.
        lines.first { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.count >= 3 && trimmed.rangeOfCharacter(from: .letters) != nil
        }
    }
}
