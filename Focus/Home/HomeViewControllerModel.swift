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


    func schedulePomodoroSessionNotifications() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settingsInfo in
            guard settingsInfo.authorizationStatus == .authorized else {
                print("Нет разрешения на уведомления")
                return
            }

            center.removeAllPendingNotificationRequests()

            var currentTime: TimeInterval = 0

            for session in 1...self.settings.pomodorosBeforeLongBreak {
                // Помодоро сессия
                currentTime += self.settings.workDuration * 60
                let workContent = UNMutableNotificationContent()
                workContent.title = "Сессия \(session) завершена!"
                workContent.body = "Сделай короткий перерыв."
                workContent.sound = .default

                let workTrigger = UNTimeIntervalNotificationTrigger(timeInterval: currentTime, repeats: false)
                let workRequest = UNNotificationRequest(identifier: "work_session_\(session)", content: workContent, trigger: workTrigger)
                center.add(workRequest)

                print("Добавлено уведомление о завершении сессии \(session) через \(currentTime) секунд.")

                if session == self.settings.pomodorosBeforeLongBreak {
                    // длинный перерыв после последней сессии
                    currentTime += self.settings.longBreakDuration * 60
                    let longBreakContent = UNMutableNotificationContent()
                    longBreakContent.title = "Поздравляем!"
                    longBreakContent.body = "Ты завершил все \(self.settings.pomodorosBeforeLongBreak) сессий. Сделай длинный перерыв!"
                    longBreakContent.sound = .default

                    let longBreakTrigger = UNTimeIntervalNotificationTrigger(timeInterval: currentTime, repeats: false)
                    let longBreakRequest = UNNotificationRequest(identifier: "long_break", content: longBreakContent, trigger: longBreakTrigger)
                    center.add(longBreakRequest)

                    print("Добавлено уведомление о длинном перерыве через \(currentTime) секунд.")
                } else {
                    // короткий перерыв после каждой сессии кроме последней
                    currentTime += self.settings.shortBreakDuration * 60
                }
            }
        }
    }


    
    // рабочий варант
//    func scheduleFullPomodoroSessionNotifications() {
//        let center = UNUserNotificationCenter.current()
//
//        // Проверка на разрешение
//        center.getNotificationSettings { settings in
//            guard settings.authorizationStatus == .authorized else {
//                print("Нет разрешения на уведомления")
//                return
//            }
//
//            // Очищаем все старые уведомления перед новой серией
//            center.removeAllPendingNotificationRequests()
//
//            // Создаём уведомления
//            let intervals: [TimeInterval] = [60, 120, 2700] // 25мин, 30мин, 45мин (в секундах)
//            let titles = ["Помодоро завершён!", "Перерыв завершён!", "Сессия завершена!"]
//            let bodies = ["Сделай паузу!", "Пора работать!", "Отличная работа, сделай длинный перерыв!"]
//
//            for i in 0..<intervals.count {
//                let content = UNMutableNotificationContent()
//                content.title = titles[i]
//                content.body = bodies[i]
//                content.sound = .default
//
//                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervals[i], repeats: false)
//                let request = UNNotificationRequest(identifier: "notification_\(i)", content: content, trigger: trigger)
//
//                center.add(request) { error in
//                    if let error = error {
//                        print("Ошибка добавления уведомления: \(error.localizedDescription)")
//                    } else {
//                        print("Уведомление \(i+1) добавлено")
//                    }
//                }
//            }
//        }
//    }


    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
 // норм вариант
    
//     func scheduleCompletionNotification() {
//        cancelPendingNotifiction()
//        let content = UNMutableNotificationContent()
//        content.title = "Focus"
//        switch currentState {
//        case .work:
//            content.body = Resouces.Text.Label.notificationBody
//        case .shortBreak:
//            content.body = "Короткий перерыв окончен. Время работать"
//        case .longBreak:
//            content.body = "Длинный перерыв окончен"
//        case .paused:
//            return
//        }
//        
//        content.sound = .default
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
//        
//        notificationIdentifier = UUID().uuidString
//        
//        let request = UNNotificationRequest(identifier: notificationIdentifier!, content: content, trigger: trigger)
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Ошибка планирования уведомления")
//            }
//        }
//    }
    
    private func cancelPendingNotifiction() {
        guard let notificationIdentifier = notificationIdentifier else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    func startTimer() {
        //cancelPendingNotifiction()
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
        //scheduleCompletionNotification()
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
        cancelPendingNotifiction()
    }
    
    func resumeTimer() {
        if let pauseTime = lastPausedTime {
            let now = TimeSyncService.shared.currentServerTime()
            totalPausedTime += now.timeIntervalSince(pauseTime)
            lastPausedTime = nil
        }
        startTimer()
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
        cancelPendingNotifiction()
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
