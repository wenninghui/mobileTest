//  BookingCache.swift
//  MobileTest
//
//  Created by wen ninghui on 2025/9/2.
//

import Foundation

struct BookingCacheEntry: Codable, Equatable {
    let booking: Booking
    let savedAt: Date
}

protocol BookingCaching {
    func read() throws -> BookingCacheEntry?
    func write(_ entry: BookingCacheEntry) throws
    func clear() throws
}

final class BookingCache: BookingCaching {
    private let fileURL: URL
    private let fm = FileManager.default

    init(fileName: String = "booking_cache.json") {
        let urls = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        self.fileURL = urls[0].appendingPathComponent(fileName)
    }

    func read() throws -> BookingCacheEntry? {
        guard fm.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(BookingCacheEntry.self, from: data)
        } catch {
            throw BookingError.cacheReadFailed
        }
    }

    func write(_ entry: BookingCacheEntry) throws {
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw BookingError.cacheWriteFailed
        }
    }

    func clear() throws {
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
        }
    }
}
