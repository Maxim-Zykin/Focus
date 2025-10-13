//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation
import UserNotifications
import UIKit
import AVFoundation

struct PomodoroSettings {
    var workDuration: TimeInterval // в минутах
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var pomodorosBeforeLongBreak: Int
    
    static let `default` = PomodoroSettings(
        workDuration: 7,
        shortBreakDuration: 2,
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
    private var audioPlayer: AVAudioPlayer?
    private var awaitingManualStartAfterLongBreak = false
    private var progressAtPause: Double?

    
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
        observerAudioInterruptions()
    }

    // MARK: - Timer Logic
    func startTimer() {
        startBackgroundAudio()
        awaitingManualStartAfterLongBreak = false
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
        tick()
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
        
        currentState = restoreState
        sessionEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
        isTimerActive = true
        
        scheduleNotifications()
        startBackgroundAudio()
        stateChanged?(currentState)
        tick()
    }


    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
        timerStopped?()
        stopBackgroundAudio()
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
        stopBackgroundAudio()

    }
    
    private func tick() {
        guard let end = sessionEndDate else { return }
        
        if currentState == .paused {
            return
        }
        
        timeRemaining = max(Int(end.timeIntervalSinceNow), 0)
        
        debugLog()
        
        DispatchQueue.main.async {
            [weak self] in
            self?.updateDisplay()
        }
        if timeRemaining <= 0 {
            transitionToNextState()
        }
    }


    private func transitionToNextState() {
        print("Переход к следующему состоянию")
        
        switch currentState {
        case .work:
            cyclesCompleted += 1
            if shouldTakeLongBreak() {
                currentState = .longBreak
                pomodorosUpdated?(pomodorosCompleted)
            } else {
                currentState = .shortBreak
                pomodorosUpdated?(pomodorosCompleted)
            }
            
        case .shortBreak:
            currentState = .work
            
        case .longBreak:
            cyclesCompleted = 0
            currentState = .work
            awaitingManualStartAfterLongBreak = true
            
        case .paused:
            return
        }
        
        resetTimerForCurrentState()
        
        if awaitingManualStartAfterLongBreak {
            sessionStartDate = nil
            sessionEndDate = nil
            stateChanged?(currentState)
            updateDisplay()
            stopTimer()
            cancelAllNotifications()
            print("Новый цикл начинается вручную после длинного перерыва")
            return
        }
        
        sessionStartDate = Date()
        sessionEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        stateChanged?(currentState)
        updateDisplay()
        debugLog()
        
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
    
    // MARK: - Observers
    private func observerAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        print("Обработка аудиопрерывания")
        
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            print("Начало звонка - пауза")
            // Ставим на паузу если таймер активен
            if isTimerActive && currentState != .paused {
                pauseTimer()
            }
            stopBackgroundAudio()

        case .ended:
            print("Конец звонка - попытка возобновления")
            
            // Активируем аудиосессию
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("Аудиосессия активирована")
            } catch {
                print("Ошибка аудиосессии: \(error)")
            }
            
            startBackgroundAudio()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                print("Проверка для возобновления:")
                print("   - currentState: \(self.currentState)")
                print("   - pausedState: \(String(describing: self.pausedState))")
                
                // Если мы на паузе и есть сохраненное состояние - возобновляем
                if self.currentState == .paused {
                    print("Находимся в состоянии паузы - вызываем resumeTimer()")
                    self.resumeTimer()
                } else {
                    print("Не в состоянии паузы, возобновление не требуется")
                }
            }
            
        @unknown default:
            break
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

        // Добавьте проверку на awaitingManualStartAfterLongBreak
        if timeRemaining <= 0 && !awaitingManualStartAfterLongBreak {
            transitionToNextState()
        } else if isTimerActive && timer == nil && !awaitingManualStartAfterLongBreak {
            // Возобновляем таймер только если не ожидаем ручного старта
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
    
    private func startBackgroundAudio() {
        guard let url = Bundle.main.url(forResource: "silence", withExtension: "wav") else {
            print("Файл silence.mp3 не найден")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 //  бесконечно
            audioPlayer?.volume = 0.01
            audioPlayer?.play()
            
            print("Запущено фоновое аудио")
        } catch {
            print("Ошибка запуска аудио: \(error)")
        }
    }

    private func stopBackgroundAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        print("Фоновое аудио остановлено")
    }

    // MARK: - UI Updates
    func updateDisplay() {
            self.updateTimeLabel()
            self.updateProgress()
    }
    
    private func updateTimeLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerUpdated?(String(format: "%02d:%02d", minutes, seconds))
    }
    
    private func updateProgress() {
        let stateForTotal: TimerState = (currentState == .paused ? (pausedState ?? .work) : currentState)

        let total: Int
        switch stateForTotal {
        case .work:       total = workDuration
        case .shortBreak: total = shortBreakDuration
        case .longBreak:  total = longBreakDuration
        case .paused:
            total = max(workDuration, shortBreakDuration, longBreakDuration)
        }

        guard total > 0 else {
            progressUpdated?(1.0)
            return
        }
        let ratio = max(0, min(1, CGFloat(Double(timeRemaining) / Double(total))))
        progressUpdated?(ratio)
    }

    // MARK: - Notifications
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleNotifications() {
        guard let endDate = sessionEndDate else { return }
        
        let interval = endDate.timeIntervalSinceNow
        guard interval > 1 else {
            print("Слишком маленький интервал для уведомления: \(interval)")
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
            content.title = Resouces.Text.Label.longBreakIsOverTitle //"🎉 Длинный перерыв окончен!"
            content.body = Resouces.Text.Label.longBreakIsOver //"Можно начинать новый цикл."
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
                print(" Ошибка добавления уведомления: \(error.localizedDescription)")
            } else {
                print("Уведомление запланировано через \(Int(interval)) сек.")
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

