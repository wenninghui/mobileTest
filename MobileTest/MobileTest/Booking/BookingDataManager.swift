//  BookingDataManager.swift
//  MobileTest
//
//  Created by wen ninghui on 2025/9/2.
//

import Foundation

enum FetchPolicy {
    case cacheFirstThenRefresh
    case refreshOnly
}

protocol BookingProviding {
    func fetchBooking(policy: FetchPolicy, completion: @escaping (Result<Booking, BookingError>) -> Void, onUpdate: ((Booking) -> Void)?)
    func invalidateCache()
}

final class BookingDataManager: BookingProviding {
    private let service: BookingServicing =  BookingService()
    private let cache: BookingCaching = BookingCache()
    private let queue = DispatchQueue(label: "BookingDataManager")

    private let cacheTTL: TimeInterval = 10 * 60


    func fetchBooking(policy: FetchPolicy, completion: @escaping (Result<Booking, BookingError>) -> Void, onUpdate: ((Booking) -> Void)?) {
        switch policy {
        case .cacheFirstThenRefresh:
            // Try cache first
            var deliveredCached = false
            if let cached = try? cache.read(), !isStale(entry: cached) {
                deliveredCached = true
                completion(.success(cached.booking))
            }
            // Always refresh in background
            service.fetchBooking { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let booking):
                    let entry = BookingCacheEntry(booking: booking, savedAt: Date())
                    try? self.cache.write(entry)
                    if deliveredCached {
                        onUpdate?(booking)
                    } else {
                        completion(.success(booking))
                    }
                case .failure(let error):
                    if !deliveredCached {
                        // Fallback to stale cache if available
                        if let cached = try? self.cache.read() {
                            completion(.success(cached.booking))
                        } else {
                            completion(.failure(error))
                        }
                    }
                }
            }
        case .refreshOnly:
            service.fetchBooking { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let booking):
                    let entry = BookingCacheEntry(booking: booking, savedAt: Date())
                    try? self.cache.write(entry)
                    completion(.success(booking))
                case .failure(let error):
                    // Try cache as fallback
                    if let cached = try? self.cache.read() {
                        completion(.success(cached.booking))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func invalidateCache() {
        try? cache.clear()
    }

    private func isStale(entry: BookingCacheEntry) -> Bool {
        let ttlExpired = Date().timeIntervalSince(entry.savedAt) > cacheTTL
        let expiredByBooking = (entry.booking.expiryDate ?? .distantFuture) < Date()
        return ttlExpired || expiredByBooking
    }
}
