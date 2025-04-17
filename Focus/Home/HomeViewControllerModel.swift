//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation

class HomeViewControllerModel {
    
    private var timer: Timer?
    
    var duretionTimer = 2 * 6
    var breakDuretion = 5 * 5
    
    private var workDuration: Int = 2 * 6 // 20 минут в секундах
    private var shortBreakDuration: Int = 5 * 6 // 5 минут
    private var longBreakDuration: Int = 15 * 60 // 15 минут
    private var quantity = 4
    
    var timerUpdated: ((String) -> Void)?
    var timerStarted: (() -> Void)?
    var timerStopped:(() -> Void)?
    var timerReset:(() -> Void)?
    var updatedAnimation:(() -> Void)?
    var onTimeUpdated: ((String) -> Void)?
    
    var timeRemaining: TimeInterval = 0 {
        didSet {
            onTimeUpdated?(formattedTime())
        }
    }

    func startTimer(){
        stopTimer() 
       let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
        
               if workDuration > 0 {
                   workDuration -= 1
                   duretionTimer = workDuration
                   updateTimeLabel()
               } else if workDuration == 0 {
                   shortBreakDuration -= 1
                   duretionTimer = shortBreakDuration
                   updateTimeLabel()
               }
        }
        timerStarted?()
       RunLoop.current.add(newTimer, forMode: .common)
       timer = newTimer
        updateTimeLabel()
    }
    
    func newCycle() {
        duretionTimer = workDuration
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerStopped?()
        duretionTimer = workDuration
    }
    
    func resetTimer(to initialValue: Int = 2 * 6) {
        timer = nil
        stopTimer()
        duretionTimer = initialValue
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
    
    func formattedTime() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


