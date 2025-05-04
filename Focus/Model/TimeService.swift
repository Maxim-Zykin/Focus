//
//  TimeService.swift
//  Focus
//
//  Created by Максим Зыкин on 03.05.2025.
//

import Foundation

import Foundation
import Network

class TimeSyncService {
    static let shared = TimeSyncService()
    private var timeDifference: TimeInterval = 0
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = false
    
    init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    func syncTime(completion: @escaping (Result<Bool, TimeSyncError>) -> Void) {
        guard isNetworkAvailable else {
            completion(.failure(.noInternetConnection))
            return
        }
        
        guard let url = URL(string: "https://worldtimeapi.org/api/ip") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let request = URLRequest(url: url, timeoutInterval: 5)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noDataReceived))
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TimeResponse.self, from: data)
                let serverTime = response.unixtime
                let localTime = Date().timeIntervalSince1970
                self.timeDifference = serverTime - localTime
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        
        task.resume()
    }
    
    func currentServerTime() -> Date {
        return Date().addingTimeInterval(timeDifference)
    }
}

enum TimeSyncError: Error, LocalizedError {
    case noInternetConnection
    case invalidURL
    case networkError(Error)
    case serverError
    case noDataReceived
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "Отсутствует интернет-соединение"
        case .invalidURL:
            return "Неверный URL сервера времени"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .serverError:
            return "Ошибка сервера времени"
        case .noDataReceived:
            return "Не получены данные от сервера"
        case .decodingError(let error):
            return "Ошибка обработки данных: \(error.localizedDescription)"
        }
    }
}

struct TimeResponse: Codable {
    let unixtime: TimeInterval
}
