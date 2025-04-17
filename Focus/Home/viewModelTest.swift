//
//  viewModelTest.swift
//  Focus
//
//  Created by Максим Зыкин on 21.03.2025.
//

import Foundation
import Foundation


import Foundation

enum TimerState {
    case work
    case shortBreak
    case longBreak
    case paused
    case stopped
}

struct PomodoroSettings {
    var workDuration: TimeInterval // в минутах
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var pomodorosBeforeLongBreak: Int
    
    static let `default` = PomodoroSettings(
        workDuration: 1,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        pomodorosBeforeLongBreak: 4
    )
}

class PomodoroTimer {
    private var timer: Timer?
    private var totalSeconds: TimeInterval = 0
    private(set) var timeRemaining: TimeInterval = 0
    private(set) var timerState: TimerState = .stopped
    private(set) var completedPomodoros = 0
    
    var settings: PomodoroSettings = .default
    var onTick: ((TimeInterval) -> Void)?
    var onStateChange: ((TimerState) -> Void)?
    var onPomodoroComplete: (() -> Void)?
    
    init() {
        reset()
    }
    
    // Запуск работы
    func startWork() {
        startTimer(duration: settings.workDuration * 60, state: .work)
    }
    
    // Запуск короткого перерыва
    func startShortBreak() {
        startTimer(duration: settings.shortBreakDuration * 60, state: .shortBreak)
    }
    
    // Запуск длинного перерыва
    func startLongBreak() {
        startTimer(duration: settings.longBreakDuration * 60, state: .longBreak)
    }
    
    // Пауза
    func pause() {
        timer?.invalidate()
        timer = nil
        timerState = .paused
        onStateChange?(timerState)
    }
    
    // Продолжить
    func resume() {
        startTimer(duration: timeRemaining, state: timerState)
    }
    
    // Остановить
    func stop() {
        timer?.invalidate()
        timer = nil
        timerState = .stopped
        reset()
        onStateChange?(timerState)
    }
    
    // Переключить паузу/продолжить
    func togglePause() {
        if timer == nil && timerState != .stopped {
            resume()
        } else {
            pause()
        }
    }
    
    private func startTimer(duration: TimeInterval, state: TimerState) {
        timer?.invalidate()
        totalSeconds = duration
        timeRemaining = duration
        timerState = state
        onStateChange?(timerState)
        onTick?(timeRemaining)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.onTick?(self.timeRemaining)
            } else {
                self.timerFinished()
            }
        }
    }
    
    private func timerFinished() {
        timer?.invalidate()
        timer = nil
        
        switch timerState {
        case .work:
            completedPomodoros += 1
            onPomodoroComplete?()
            if completedPomodoros % settings.pomodorosBeforeLongBreak == 0 {
                startLongBreak()
            } else {
                startShortBreak()
            }
        case .shortBreak, .longBreak:
            startWork()
        default:
            break
        }
    }
    
    private func reset() {
        timeRemaining = settings.workDuration * 60
        totalSeconds = settings.workDuration * 60
    }
    
    // Форматирование времени для отображения
    func formattedTime() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Прогресс таймера (от 0 до 1)
    func progress() -> Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (timeRemaining / totalSeconds)
    }
}
//
//class PomodoroTimerViewModel {
//    // Наблюдаемые свойства
//    var timeRemaining: TimeInterval = 0 {
//        didSet {
//            onTimeUpdated?(formattedTime())
//        }
//    }
//    
//    var timerState: TimerState = .stopped {
//        didSet {
//            onStateUpdated?(timerState)
//        }
//    }
//    
//    var completedPomodoros = 0 {
//        didSet {
//            onPomodorosUpdated?(completedPomodoros)
//        }
//    }
//    
//    // Замыкания для обновления UI
//    var onTimeUpdated: ((String) -> Void)?
//    var onStateUpdated: ((TimerState) -> Void)?
//    var onPomodorosUpdated: ((Int) -> Void)?
//    var onProgressUpdated: ((Double) -> Void)?
//    
//    // Настройки таймера
//    var settings: PomodoroSettings
//    private var timer: Timer?
//    private var totalSeconds: TimeInterval = 0
//    
//    init(settings: PomodoroSettings = .default) {
//        self.settings = settings
//        self.timeRemaining = settings.workDuration * 60
//        self.totalSeconds = settings.workDuration * 60
//    }
//    
//    // Запуск работы
//    func startWork() {
//        startTimer(duration: settings.workDuration * 60, state: .work)
//    }
//    
//    // Запуск короткого перерыва
//    func startShortBreak() {
//        startTimer(duration: settings.shortBreakDuration * 60, state: .shortBreak)
//    }
//    
//    // Запуск длинного перерыва
//    func startLongBreak() {
//        startTimer(duration: settings.longBreakDuration * 60, state: .longBreak)
//    }
//    
//    // Пауза
//    func pause() {
//        timer?.invalidate()
//        timer = nil
//        timerState = .paused
//    }
//    
//    // Продолжить
//    func resume() {
//        startTimer(duration: timeRemaining, state: timerState)
//    }
//    
//    // Остановить
//    func stop() {
//        timer?.invalidate()
//        timer = nil
//        timerState = .stopped
//        if case .work = timerState {
//            timeRemaining = settings.workDuration * 60
//        } else {
//            timeRemaining = settings.shortBreakDuration * 60
//        }
//        onProgressUpdated?(0)
//    }
//    
//    // Переключить паузу/продолжить
//    func togglePause() {
//        if timer == nil && timerState != .stopped {
//            resume()
//        } else {
//            pause()
//        }
//    }
//    
//    private func startTimer(duration: TimeInterval, state: TimerState) {
//        timer?.invalidate()
//        totalSeconds = duration
//        timeRemaining = duration
//        timerState = state
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            
//            if self.timeRemaining > 0 {
//                self.timeRemaining -= 1
//                let progress = 1 - (self.timeRemaining / self.totalSeconds)
//                self.onProgressUpdated?(progress)
//            } else {
//                self.timerFinished()
//            }
//        }
//    }
//    
//    private func timerFinished() {
//        timer?.invalidate()
//        timer = nil
//        
//        switch timerState {
//        case .work:
//            completedPomodoros += 1
//            if completedPomodoros % settings.pomodorosBeforeLongBreak == 0 {
//                startLongBreak()
//            } else {
//                startShortBreak()
//            }
//        case .shortBreak, .longBreak:
//            startWork()
//        default:
//            break
//        }
//    }
//    
//    // Форматирование времени для отображения
//    func formattedTime() -> String {
//        let minutes = Int(timeRemaining) / 60
//        let seconds = Int(timeRemaining) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//}
//*//
