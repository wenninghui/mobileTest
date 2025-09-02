//
//  BookingModel.swift
//  MobileTest
//
//  Created by wen ninghui on 2025/9/2.
//

import Foundation

// MARK: - Models mapping booking.json

struct Booking: Codable, Equatable {
    let shipReference: String
    let shipToken: String
    let canIssueTicketChecking: Bool
    let expiryTime: String
    let duration: Int
    let segments: [Segment]

    var expiryDate: Date? {
        if let seconds = TimeInterval(expiryTime) { return Date(timeIntervalSince1970: seconds) }
        return nil
    }
}

struct Segment: Codable, Equatable {
    let id: Int
    let originAndDestinationPair: OriginDestinationPair
}

struct OriginDestinationPair: Codable, Equatable {
    let destination: Place
    let destinationCity: String
    let origin: Place
    let originCity: String
}

struct Place: Codable, Equatable {
    let code: String
    let displayName: String
    let url: String
}

// MARK: - Errors

enum BookingError: Error, LocalizedError, Equatable {
    case fileNotFound
    case decodingFailed
    case encodingFailed
    case cacheWriteFailed
    case cacheReadFailed
    // Network-related
    case urlInvalid
    case networkUnavailable
    case timeout
    case invalidResponse
    case requestFailed(code: Int?)
    case unknown

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "booking.json not found in bundle"
        case .decodingFailed: return "Failed to decode booking data"
        case .encodingFailed: return "Failed to encode booking for cache"
        case .cacheWriteFailed: return "Failed to write booking cache"
        case .cacheReadFailed: return "Failed to read booking cache"
        case .urlInvalid: return "Invalid request URL"
        case .networkUnavailable: return "Network unavailable"
        case .timeout: return "The request timed out"
        case .invalidResponse: return "Invalid server response"
        case .requestFailed(let code):
            if let c = code { return "Request failed with status code: \(c)" }
            return "Request failed"
        case .unknown: return "Unknown error"
        }
    }
}
