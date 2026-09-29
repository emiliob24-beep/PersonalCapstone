//
//  VINDecodeResult.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//

import Foundation

struct VINDecodeResult: Decodable {
    let make: String
    let model: String
    let modelYear: String
    let series: String?
    let errorCode: String
    let errorText: String

    enum CodingKeys: String, CodingKey {
        case make = "Make"
        case model = "Model"
        case modelYear = "ModelYear"
        case series = "Series"
        case errorCode = "ErrorCode"
        case errorText = "ErrorText"
    }
}

private struct VINDecodeResponse: Decodable {
    let Results: [VINDecodeResult]
}

enum VINDecoderError: LocalizedError {
    case invalidVIN
    case networkError
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            return "That doesn't look like a valid VIN — it should be 17 characters."
        case .networkError:
            return "Couldn't reach the VIN lookup service. Check your connection and try again."
        case .notFound:
            return "No vehicle found for that VIN. You can still enter details manually."
        }
    }
}

enum VINDecoderService {
    static func decode(vin: String) async throws -> VINDecodeResult {
        let trimmed = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard trimmed.count == 17 else {
            throw VINDecoderError.invalidVIN
        }

        guard let encodedVIN = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/\(encodedVIN)?format=json") else {
            throw VINDecoderError.networkError
        }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw VINDecoderError.networkError
        }

        let decoded: VINDecodeResponse
        do {
            decoded = try JSONDecoder().decode(VINDecodeResponse.self, from: data)
        } catch {
            throw VINDecoderError.networkError
        }

        guard let result = decoded.Results.first,
              !result.make.isEmpty,
              !result.model.isEmpty else {
            throw VINDecoderError.notFound
        }

        return result
    }
}
