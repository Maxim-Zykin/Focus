//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation
import UserNotifications

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
    private var lastSyncSuccess: Bool = false
    private var lastSyncTime: Date?
    private let syncTimeInterval: TimeInterval = 3600 // Синхронизировать каждые 60 минут
    private let maxCacheTime: TimeInterval = 3600
    private var notificationIdentifier: String?
    private let endDateKey = "pomodoroEndDate"

    
    // Текущее состояние
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
    var timerCompleted: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        updateDurationsFromSettings()
        timeRemaining = workDuration
       // scheduleCompletionNotification()
        cancelPendingNotifiction()
    }
    
    // MARK: - Public Methods
    
    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
            } else if !granted {
                print("Пользователь отклонил уведомления")
            }
        }
    }

    func scheduleNotifications(from timeRemaining: Int, cyclesCompleted: Int, state: TimerState) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settingsInfo in
            guard settingsInfo.authorizationStatus == .authorized else {
                print("Нет разрешения на уведомления")
                return
            }

            center.removeAllPendingNotificationRequests()

            var currentTime: TimeInterval = TimeInterval(timeRemaining)
            var currentCycle = cyclesCompleted
            var currentState = state
            
                    if currentTime == 0 && currentState == .work {
                        currentTime += self.settings.workDuration * 60
                    }

            while currentCycle < self.settings.pomodorosBeforeLongBreak - 1 {
                switch currentState {
                case .work:
                    // Завершение работы
                    let workContent = UNMutableNotificationContent()
                    workContent.title = Resouces.Text.Label.session + " " + "\(currentCycle+1)" + " " + Resouces.Text.Label.sessionIsCompleted
                    workContent.body = Resouces.Text.Label.shortBreak
                    workContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Pomodoro.wav"))

                    let workTrigger = UNTimeIntervalNotificationTrigger(timeInterval: currentTime, repeats: false)
                    let workRequest = UNNotificationRequest(identifier: "work_session_\(currentCycle+1)", content: workContent, trigger: workTrigger)
                    center.add(workRequest)

                    currentTime += self.settings.shortBreakDuration * 60
                    currentState = .shortBreak

                case .shortBreak:
                    // Завершение короткого перерыва
                    let breakContent = UNMutableNotificationContent()
                    breakContent.title = Resouces.Text.Label.breakIsCompleted
                    breakContent.body = Resouces.Text.Label.timeForWork
                    breakContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Pomodoro.wav"))

                    let breakTrigger = UNTimeIntervalNotificationTrigger(timeInterval: currentTime, repeats: false)
                    let breakRequest = UNNotificationRequest(identifier: "break_\(currentCycle+1)", content: breakContent, trigger: breakTrigger)
                    center.add(breakRequest)

                    currentCycle += 1
                    currentTime += self.settings.workDuration * 60
                    currentState = .work

                case .longBreak:
                    print("Длинный перерыв, уведомления больше не ставятся")
                    return
                    
                case .paused:
                    return
                }
            }

            // длинный перерыв после всех циклов
            let longBreakContent = UNMutableNotificationContent()
            longBreakContent.title = "Поздравляем!"
            longBreakContent.body = "Ты завершил все \(self.settings.pomodorosBeforeLongBreak) сессий. Сделай длинный перерыв!"
            longBreakContent.sound = .default

            let longBreakTrigger = UNTimeIntervalNotificationTrigger(timeInterval: currentTime, repeats: false)
            let longBreakRequest = UNNotificationRequest(identifier: "long_break_final", content: longBreakContent, trigger: longBreakTrigger)
            center.add(longBreakRequest)
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Все уведомления удалены")
    }
    
    private func cancelPendingNotifiction() {
        guard let notificationIdentifier = notificationIdentifier else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }

    func startTimer() {
        //cancelPendingNotifiction()
        guard timer == nil else { return }
        guard currentState != .longBreak else {
            print("Длинный перерыв — уведомления не ставим")
            return
        }
        recalculateTimeRemaining()
        if currentState == .paused {
            // Продолжаем с того же места
           currentState = getNextState()
            currentState = pausedState
        } else {
            // Начинаем новый цикл
            resetTimerForCurrentState()
        }
        
        let endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        UserDefaults.standard.set(endDate, forKey: endDateKey)

        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        timerStarted?()
        stateChanged?(currentState)
        //scheduleCompletionNotification()
    }
    
    func pauseTimer() {
        guard currentState != .paused else { return }
        pausedState = currentState
        timer?.invalidate()
        timer = nil
        currentState = .paused
        timerStopped?()
        stateChanged?(.paused)
        cancelAllNotifications()
        UserDefaults.standard.removeObject(forKey: endDateKey)
        print("Таймер на паузе, уведомления удалены")
    }
    
//    func resumeTimer() {
//        guard currentState != .longBreak else {
//            print("Длинный перерыв — уведомления не ставим")
//            return
//        }
//        if let remaining = getRemainingTimeFromSavedDate() {
//            timeRemaining = remaining
//        }
//        startTimer()
//        scheduleNotifications(from: timeRemaining, cyclesCompleted: cyclesCompleted, state: currentState)
//    }

    func resumeTimer() {
        guard currentState != .longBreak else {
            print("Длинный перерыв — уведомления не ставим")
            return
        }
        recalculateTimeRemaining()
        if timeRemaining <= 0 {
            transitionToNextState()
        } else {
            startTimer()
            scheduleNotifications(from: timeRemaining, cyclesCompleted: cyclesCompleted, state: currentState)
        }
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
        cancelPendingNotifiction()
        stopTimer()
        currentState = .work
        cyclesCompleted = 0
        resetTimerForCurrentState()
        timerReset?()
        stateChanged?(currentState)
        pomodorosUpdated?(0)
        UserDefaults.standard.removeObject(forKey: endDateKey)

    }
    
    func updateTimeAfterBackground() {
        // Принудительно обновляем время
        TimeSyncService.shared.syncTime { [weak self] _ in
            self?.updateDisplay()
            print("hard updateDisplay")
        }
    }
    
    // MARK: - Private Methods
    
    func recalculateTimeRemaining() {
        guard let endDate = UserDefaults.standard.object(forKey: endDateKey) as? Date else { return }
        let remaining = Int(endDate.timeIntervalSinceNow)
        timeRemaining = max(remaining, 0)
    }

    
//    private func getRemainingTimeFromSavedDate() -> Int? {
//        guard let endDate = UserDefaults.standard.object(forKey: endDateKey) as? Date else { return nil }
//        let remaining = Int(endDate.timeIntervalSinceNow)
//        return remaining > 0 ? remaining : 0
//    }
    
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
        print("Переход к следующему состоянию")
        switch currentState {
        case .work:
            cyclesCompleted += 1
            currentState = shouldTakeLongBreak() ? .longBreak : .shortBreak
            pomodorosUpdated?(pomodorosCompleted)
        case .shortBreak:
            currentState = .work
        case .longBreak:
            resetTimer()
            return
        case .paused:
            return
        }
        resetTimerForCurrentState()
        stateChanged?(currentState)
        startTimer()
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
