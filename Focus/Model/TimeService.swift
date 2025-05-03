//
//  TimeService.swift
//  Focus
//
//  Created by Максим Зыкин on 03.05.2025.
//

import Foundation

class TimeSyncService {
    static let shared = TimeSyncService()
    private var timeDifference: TimeInterval = 0
    
    func syncTime(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://worldtimeapi.org/api/ip") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TimeResponse.self, from: data)
                let serverTime = response.unixtime
                let localTime = Date().timeIntervalSince1970
                self.timeDifference = serverTime - localTime
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
    
    func currentServerTime() -> Date {
        return Date().addingTimeInterval(timeDifference)
    }
}

struct TimeResponse: Codable {
    let unixtime: TimeInterval
}
