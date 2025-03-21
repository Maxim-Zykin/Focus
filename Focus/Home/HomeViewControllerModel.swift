//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation

protocol HomeViewControllerModelProtocol {
    func timerAction(completion: @escaping () -> Void)
}

class HomeViewControllerModel: HomeViewControllerModelProtocol {
    
   private let timer = Timer()
    
    var duretionTimer = 150
    
    func timerAction(completion: @escaping () -> Void){
        if duretionTimer > 0 {
            duretionTimer -= 1
            print(duretionTimer)
        }
    }
    
    func formatedTimer() {
        let date = Date(timeIntervalSince1970: TimeInterval(duretionTimer))
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let formattedTime = formatter.string(from: date)
    }
}

