//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation

class HomeViewControllerModel {
    
    private var timer: Timer?
    
    var duretionTimer = 9
    
    var timerUpdated: ((String) -> Void)?
    var timerStarted: (() -> Void)?
    var timerStopped:(() -> Void)?
    var timerReset:(() -> Void)?

    func startTimer(){
        stopTimer() 
       let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if duretionTimer > 0 {
                self.duretionTimer -= 1
                self.updateTimeLabel()
            }
        }
        timerStarted?()
       RunLoop.current.add(newTimer, forMode: .common)
       timer = newTimer
        updateTimeLabel()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timerStopped?()
    }
    
    func resetTimer(to initialValue: Int = 900) {
        stopTimer()
        duretionTimer = initialValue
        timerReset?()
        updateTimeLabel()
    }
    
    private func updateTimeLabel() {
        
        let date = Date(timeIntervalSince1970: TimeInterval(duretionTimer))
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let formattedTime = formatter.string(from: date)
        timerUpdated?(formattedTime)
            }
}


