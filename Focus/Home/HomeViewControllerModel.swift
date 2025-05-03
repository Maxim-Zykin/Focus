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
        workDuration: 25,
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
    private var startServerTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var lastPausedTime: Date?
    
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
        TimeSyncService.shared.syncTime { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.startServerTime = TimeSyncService.shared.currentServerTime()
                    self.totalPausedTime = 0
                    self.setupLocalTimer()
                } else {
                    self.startServerTime = Date()
                    self.setupLocalTimer()
                }
            }
        }
    }
    
    private func setupLocalTimer() {
        guard timer == nil else { return }
        
        if currentState == .paused {
            // Продолжаем с того же места
           currentState = getNextState()
            currentState = pausedState
        } else {
            // Начинаем новый цикл
            resetTimerForCurrentState()
            
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        timerStarted?()
        stateChanged?(currentState)
    }
    
    func pauseTimer() {
        lastPausedTime = TimeSyncService.shared.currentServerTime()
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
    
    func resumeTimer() {
        if let pauseTime = lastPausedTime {
            let now = TimeSyncService.shared.currentServerTime()
            totalPausedTime += now.timeIntervalSince(pauseTime)
            lastPausedTime = nil
        }
        setupLocalTimer()
    }
    
    func currentElapsedTime() -> TimeInterval {
        guard let start = startServerTime else { return 0 }
        let now = TimeSyncService.shared.currentServerTime()
        return now.timeIntervalSince(start) - totalPausedTime
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
    
    func updateTimeAfterBackground() {
        // Принудительно обновляем время
        TimeSyncService.shared.syncTime { [weak self] _ in
            self?.updateDisplay()
            print("hard updateDisplay")
        }
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
            print(cyclesCompleted)
            currentState = shouldTakeLongBreak() ? .longBreak : .shortBreak
            pomodorosUpdated?(pomodorosCompleted)
        case .shortBreak:
            currentState = .work
        case .longBreak:
            resetTimer()
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
            print("Work")
        case .shortBreak:
            timeRemaining = shortBreakDuration
            print("Short")
        case .longBreak:
            timeRemaining = longBreakDuration
            print("Long")
        case .paused:
            break
        }
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
