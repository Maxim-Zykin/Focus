//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation
import UserNotifications
import UIKit

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
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var pausedState: TimerState?
    
    enum TimerState {
        case work
        case shortBreak
        case longBreak
        case paused
    }
    
    var currentState: TimerState = .work
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
    
    // Время сессии
    var sessionStartDate: Date?
    var sessionEndDate: Date?
    var timeRemaining: Int = 0 {
        didSet { updateDisplay() }
    }
    private(set) var isTimerActive: Bool = false
    
    // Callbacks
    var timerUpdated: ((String) -> Void)?
    var timerStarted: (() -> Void)?
    var timerStopped: (() -> Void)?
    var timerReset: (() -> Void)?
    var stateChanged: ((TimerState) -> Void)?
    var progressUpdated: ((CGFloat) -> Void)?
    var pomodorosUpdated: ((Int) -> Void)?
    var timerCompleted: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        updateDurationsFromSettings()
        timeRemaining = workDuration
        cancelAllNotifications()
    }
    
    // MARK: - Timer Logic
    func startTimer() {
        guard timer == nil else { return }
        guard currentState != .paused else { return }
        
        endBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        sessionStartDate = Date()
        sessionEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        
        scheduleNotifications()
        isTimerActive = true
        timerStarted?()
        stateChanged?(currentState)
        progressUpdated?(1.0)
    }
    
    func pauseTimer() {
        guard timer != nil else { return }
        
        timer?.invalidate()
        timer = nil
        pausedState = currentState   // сохраняет предыдущее состояние
        currentState = .paused
        isTimerActive = false
        
        cancelAllNotifications()
        stateChanged?(currentState)
        endBackgroundTask()
    }

    func resumeTimer() {
        guard currentState == .paused, timer == nil, let restoreState = pausedState else { return }
        
        currentState = restoreState   // восстанавливает правильное состояние
        sessionEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        
        isTimerActive = true
        scheduleNotifications()
        stateChanged?(currentState)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
        timerStopped?()
    }
    
    func resetTimer() {
        stopTimer()
        cancelAllNotifications()
        endBackgroundTask()
        
        sessionStartDate = nil
        sessionEndDate = nil
        
        currentState = .work
        cyclesCompleted = 0
        timeRemaining = workDuration
        
        timerReset?()
        stateChanged?(currentState)
        pomodorosUpdated?(0)
        progressUpdated?(1.0)
        updateDisplay()
    }
    
    private func tick() {
        guard let end = sessionEndDate else { return }
        timeRemaining = max(Int(end.timeIntervalSinceNow), 0)
        
        debugLog()
        
        if timeRemaining <= 0 {
            transitionToNextState()
        }
    }

    private func transitionToNextState() {
        print("➡️ Переход к следующему состоянию")
        
        switch currentState {
        case .work:
            cyclesCompleted += 1
            currentState = shouldTakeLongBreak() ? .longBreak : .shortBreak
            pomodorosUpdated?(pomodorosCompleted)
            
        case .shortBreak:
            currentState = .work
            
        case .longBreak:
            cyclesCompleted = 0
            currentState = .work
            
        case .paused:
            return
        }
        
        resetTimerForCurrentState()
        sessionStartDate = Date()
        sessionEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        stateChanged?(currentState)
        updateDisplay()
        
        debugLog() // лог после перехода
        
        stopTimer()
        startTimer()
    }

    func catchUpIfNeeded() {
        guard let endDate = sessionEndDate else { return }
        
        // если время сессии истекло, но UI ещё не обновился
        if Date() >= endDate {
            transitionToNextState()
        }
    }
    
    // MARK: - App Lifecycle
    func handleAppWillEnterForeground() {
        if currentState == .paused {
            updateDisplay()
            return
        }
        
        recalculateTimeRemaining()
        updateDisplay()
        
        if timeRemaining <= 0 {
            transitionToNextState()
        } else if isTimerActive && timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
            RunLoop.current.add(timer!, forMode: .common)
        }
    }
    
    private func recalculateTimeRemaining() {
        guard let endDate = sessionEndDate else {
            resetTimerForCurrentState()
            return
        }
        timeRemaining = max(Int(endDate.timeIntervalSinceNow), 0)
    }
    
    // MARK: - Helpers
    private func updateDurationsFromSettings() {
        workDuration = Int(settings.workDuration * 60)
        shortBreakDuration = Int(settings.shortBreakDuration * 60)
        longBreakDuration = Int(settings.longBreakDuration * 60)
    }
    
    private func resetTimerForCurrentState() {
        switch currentState {
        case .work: timeRemaining = workDuration
        case .shortBreak: timeRemaining = shortBreakDuration
        case .longBreak: timeRemaining = longBreakDuration
        case .paused: break
        }
    }
    
    private func shouldTakeLongBreak() -> Bool {
        return cyclesCompleted % settings.pomodorosBeforeLongBreak == 0
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - UI Updates
    func updateDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateTimeLabel()
            self.updateProgress()
        }
    }
    
    private func updateTimeLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerUpdated?(String(format: "%02d:%02d", minutes, seconds))
    }
    
    private func updateProgress() {
        guard let start = sessionStartDate, let end = sessionEndDate else {
            progressUpdated?(1.0)
            return
        }
        let now = Date()
        let progress = CGFloat((end.timeIntervalSince1970 - now.timeIntervalSince1970) /
                               (end.timeIntervalSince1970 - start.timeIntervalSince1970))
        progressUpdated?(max(0, min(1, progress)))
    }
    
    // MARK: - Notifications
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleNotifications() {
        guard let endDate = sessionEndDate else { return }
        
        let interval = endDate.timeIntervalSinceNow
        guard interval > 1 else {
            print("⚠️ Слишком маленький интервал для уведомления: \(interval)")
            return
        }
        
        let content = UNMutableNotificationContent()
        switch currentState {
        case .work:
            content.title = Resouces.Text.Label.workIsCompleted //"⏰ Работа завершена!"
            content.body = Resouces.Text.Label.shortBreak //"Время сделать перерыв."
        case .shortBreak:
            content.title = Resouces.Text.Label.breakIsCompleted //"☕️ Перерыв окончен!"
            content.body = Resouces.Text.Label.timeForWork //"Пора вернуться к работе."
        case .longBreak:
            content.title = "🎉 Длинный перерыв окончен!"
            content.body = "Можно начинать новый цикл."
        case .paused:
            return
        }
        content.sound = UNNotificationSound(named: UNNotificationSoundName("Pomodoro.wav"))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoro_timer_\(UUID().uuidString)",
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка добавления уведомления: \(error.localizedDescription)")
            } else {
                print("✅ Уведомление запланировано через \(Int(interval)) сек.")
            }
        }
    }

    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Debug
    private func debugLog() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        
        let stateText: String
        switch currentState {
        case .work: stateText = "Работа"
        case .shortBreak: stateText = "Короткий перерыв"
        case .longBreak: stateText = "Длинный перерыв"
        case .paused: stateText = "Пауза"
        }
        
        print(String(format: "⏱ Осталось %02d:%02d. %@, %d цикл", minutes, seconds, stateText, cyclesCompleted + 1))
    }

}
