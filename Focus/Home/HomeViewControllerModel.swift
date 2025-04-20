//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation

struct PomodoroSettings {
    var workDuration: TimeInterval // в минутах
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var pomodorosBeforeLongBreak: Int
    
    static let `default` = PomodoroSettings(
        workDuration: 1,  // Исправлено с 1 на 25 минут (стандартное значение Pomodoro)
        shortBreakDuration: 5,
        longBreakDuration: 15,
        pomodorosBeforeLongBreak: 4
    )
}

class HomeViewControllerModel {
    
    // MARK: - Properties
    private var timer: Timer?
    var settings: PomodoroSettings = .default {
        didSet {
            updateDurationsFromSettings()
            resetTimer()
        }
    }
    
    private var pausedState: TimerState = .work
    
    // Текущее состояние
    enum TimerState {
        case work
        case shortBreak
        case longBreak
        case paused
    }
    
    private(set) var currentState: TimerState = .work
     var cyclesCompleted: Int = 0 {
        didSet {
            pomodorosCompleted = cyclesCompleted % settings.pomodorosBeforeLongBreak
        }
    }
    private(set) var pomodorosCompleted: Int = 0
    
    // Длительности (в секундах)
    private var workDuration: Int = 0
    private var shortBreakDuration: Int = 0
    private var longBreakDuration: Int = 0
    
    // Текущее оставшееся время
     var timeRemaining: Int = 0 {
        didSet {
            updateDisplay()
        }
    }
    
    // Callbacks
    var timerUpdated: ((String) -> Void)?
    var timerStarted: (() -> Void)?
    var timerStopped: (() -> Void)?
    var timerReset: (() -> Void)?
    var stateChanged: ((TimerState) -> Void)?
    var progressUpdated: ((CGFloat) -> Void)?
    var pomodorosUpdated: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        updateDurationsFromSettings()
        timeRemaining = workDuration
    }
    
    // MARK: - Public Methods
    
    func startTimer() {
        guard timer == nil else { return }
        
        if currentState == .paused {
            // Продолжаем с того же места
           //currentState = getNextState()
            currentState = pausedState
//            startTimer()
//            timerStarted?()
//            stateChanged?(currentState)
        } else {
            // Начинаем новый цикл
            resetTimerForCurrentState()
//            resetTimerForCurrentState()
//            startNewTimer()
//            timerStarted?()
//            stateChanged?(currentState)
            
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        timerStarted?()
        stateChanged?(currentState)
    }
    
    func pauseTimer() {
//        timer?.invalidate()
//        timer = nil
//        let previousState = currentState
//        currentState = .paused
//        timerStopped?()
//        stateChanged?(.paused)
//        DispatchQueue.main.async {
//            self.currentState = previousState
//        }
        
        guard currentState != .paused else {
            return
        }
        pausedState = currentState
        timer?.invalidate()
        timer = nil
        currentState = .paused
        timerStopped?()
        stateChanged?(.paused)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        stopTimer()
        currentState = .work
        cyclesCompleted = 0
        resetTimerForCurrentState()
        timerReset?()
        stateChanged?(currentState)
        pomodorosUpdated?(0)
    }
    
    // MARK: - Private Methods
    
    private func updateDurationsFromSettings() {
        workDuration = Int(settings.workDuration * 60)
        shortBreakDuration = Int(settings.shortBreakDuration * 60)
        longBreakDuration = Int(settings.longBreakDuration * 60)
    }
    
    private func tick() {
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            transitionToNextState()
        }
    }
    
    private func transitionToNextState() {
        switch currentState {
        case .work:
            cyclesCompleted += 1
            currentState = shouldTakeLongBreak() ? .longBreak : .shortBreak
            pomodorosUpdated?(pomodorosCompleted)
        case .shortBreak, .longBreak:
            currentState = .work
        case .paused:
            break
        }
        
        resetTimerForCurrentState()
        stateChanged?(currentState)
    }
    
    private func resetTimerForCurrentState() {
        switch currentState {
        case .work:
            timeRemaining = workDuration
        case .shortBreak:
            timeRemaining = shortBreakDuration
        case .longBreak:
            timeRemaining = longBreakDuration
        case .paused:
            break
        }
    }
    
    private func startNewTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.tick()
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func shouldTakeLongBreak() -> Bool {
        return cyclesCompleted % settings.pomodorosBeforeLongBreak == 0
    }
    
    private func getNextState() -> TimerState {
        if currentState == .paused {
            return shouldTakeLongBreak() ? .longBreak : .shortBreak
        }
        return .work
    }
    
    private func updateDisplay() {
        updateTimeLabel()
        updateProgress()
    }
    
    private func updateTimeLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerUpdated?(String(format: "%02d:%02d", minutes, seconds))
    }
    
    private func updateProgress() {
        let totalDuration: Int
        switch currentState {
        case .work: totalDuration = workDuration
        case .shortBreak: totalDuration = shortBreakDuration
        case .longBreak: totalDuration = longBreakDuration
        case .paused: totalDuration = 1
        }
        
        let progress = CGFloat(timeRemaining) / CGFloat(totalDuration)
        progressUpdated?(progress)
    }
}


//
//class HomeViewControllerModel {
//    
//    private var timer: Timer?
//    var settings: PomodoroSettings = .default
//    
//    var duretionTimer = 2 * 6
//    var breakDuretion = 5 * 5
//    
//    private var workDuration: Int = 2 * 6 // 20 минут в секундах
//    private var shortBreakDuration: Int = 5 * 6 // 5 минут
//    private var longBreakDuration: Int = 15 * 60 // 15 минут
//    private var quantity = 4
//    
//    var timerUpdated: ((String) -> Void)?
//    var timerStarted: (() -> Void)?
//    var timerStopped:(() -> Void)?
//    var timerReset:(() -> Void)?
//    var updatedAnimation:(() -> Void)?
//    var onTimeUpdated: ((String) -> Void)?
//    
//    var timeRemaining: TimeInterval = 0 {
//        didSet {
//            onTimeUpdated?(formattedTime())
//        }
//    }
//
//    func startTimer(){
//        stopTimer() 
//       let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//        
//               if workDuration > 0 {
//                   workDuration -= 1
//                   duretionTimer = workDuration
//                   updateTimeLabel()
//               } else if workDuration == 0 {
//                   shortBreakDuration -= 1
//                   duretionTimer = shortBreakDuration
//                   updateTimeLabel()
//               }
//        }
//        timerStarted?()
//       RunLoop.current.add(newTimer, forMode: .common)
//       timer = newTimer
//        updateTimeLabel()
//    }
//    
//    func newCycle() {
//        duretionTimer = workDuration
//    }
//    
//    func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//        timerStopped?()
//        duretionTimer = workDuration
//    }
//    
//    func resetTimer(to initialValue: Int = 2 * 6) {
//        timer = nil
//        stopTimer()
//        duretionTimer = initialValue
//        updateTimeLabel()
//    }
//    
//    private func updateTimeLabel() {
//        let date = Date(timeIntervalSince1970: TimeInterval(duretionTimer))
//        let formatter = DateFormatter()
//        formatter.dateFormat = "mm:ss"
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        let formattedTime = formatter.string(from: date)
//        timerUpdated?(formattedTime)
//            }
//    
//    func formattedTime() -> String {
//        let minutes = Int(timeRemaining) / 60
//        let seconds = Int(timeRemaining) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//}
//
//
