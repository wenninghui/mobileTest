//
//  BookingService.swift
//  MobileTest
//
//  Created by wen ninghui on 2025/9/2.
//

import Foundation

protocol BookingServicing {
    func fetchBooking(completion: @escaping (Result<Booking, BookingError>) -> Void)
}

final class BookingService: BookingServicing {
    enum Source {
        case localJSON
        case network(url: URL, timeout: TimeInterval = 10)
    }
    
    private let queue = DispatchQueue(label: "BookingService", qos: .userInitiated)
    private let simulatedDelay: TimeInterval
    private let source: Source
    
    init(source: Source = .localJSON, simulatedDelay: TimeInterval = 0.5) {
        self.source = source
        self.simulatedDelay = simulatedDelay
    }
    
    func fetchBooking(completion: @escaping (Result<Booking, BookingError>) -> Void) {
        switch source {
        case .localJSON:
            queue.asyncAfter(deadline: .now() + simulatedDelay) {
                guard let url = Self.bundledJSONURL() else {
                    completion(.failure(.fileNotFound)); return
                }
                do {
                    let data = try Data(contentsOf: url)
                    let booking = try JSONDecoder().decode(Booking.self, from: data)
                    completion(.success(booking))
                } catch is DecodingError {
                    completion(.failure(.decodingFailed))
                } catch {
                    completion(.failure(.unknown))
                }
            }
        case .network(let url, let timeout):
            // Simulate latency, then make a data task
            queue.asyncAfter(deadline: .now() + simulatedDelay) {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = timeout
                config.timeoutIntervalForResource = timeout
                let session = URLSession(configuration: config)
                let task = session.dataTask(with: url) { data, response, error in
                    // Map transport errors first
                    if let err = error as? URLError {
                        switch err.code {
                        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
                            completion(.failure(.networkUnavailable))
                        case .timedOut:
                            completion(.failure(.timeout))
                        case .badURL:
                            completion(.failure(.urlInvalid))
                        default:
                            completion(.failure(.unknown))
                        }
                        return
                    } else if let error = error {
                        print("[BookingService] network error: \(error)")
                        completion(.failure(.unknown))
                        return
                    }
                    
                    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                        completion(.failure(.requestFailed(code: http.statusCode)))
                        return
                    }
                    
                    guard let data = data else {
                        completion(.failure(.invalidResponse)); return
                    }
                    do {
                        let booking = try JSONDecoder().decode(Booking.self, from: data)
                        completion(.success(booking))
                    } catch {
                        completion(.failure(.decodingFailed))
                    }
                }
                task.resume()
            }
        }
    }
    
    static func bundledJSONURL() -> URL? {
        Bundle.main.url(forResource: "booking", withExtension: "json")
    }
}
