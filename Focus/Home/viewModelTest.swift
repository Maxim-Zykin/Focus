//
//  viewModelTest.swift
//  Focus
//
//  Created by Максим Зыкин on 21.03.2025.
//

import Foundation
import Foundation

import UIKit

//class HomeViewController: UIViewController {
//    
//    // MARK: - UI Elements
//    private let timeLabel: UILabel = {
//        let label = UILabel()
//        label.font = .monospacedDigitSystemFont(ofSize: 64, weight: .bold)
//        label.textColor = .label
//        label.textAlignment = .center
//        label.text = "25:00"
//        return label
//    }()
//    
//    private let progressView: UIProgressView = {
//        let view = UIProgressView(progressViewStyle: .bar)
//        view.trackTintColor = .systemGray5
//        view.progressTintColor = .systemBlue
//        view.layer.cornerRadius = 4
//        view.clipsToBounds = true
//        return view
//    }()
//    
//    private let startButton: UIButton = {
//        var config = UIButton.Configuration.filled()
//        config.title = "Start"
//        config.baseBackgroundColor = .systemGreen
//        config.cornerStyle = .large
//        return UIButton(configuration: config)
//    }()
//    
//    private let pauseButton: UIButton = {
//        var config = UIButton.Configuration.filled()
//        config.title = "Pause"
//        config.baseBackgroundColor = .systemOrange
//        config.cornerStyle = .large
//        return UIButton(configuration: config)
//    }()
//    
//    private let resetButton: UIButton = {
//        var config = UIButton.Configuration.filled()
//        config.title = "Reset"
//        config.baseBackgroundColor = .systemRed
//        config.cornerStyle = .large
//        return UIButton(configuration: config)
//    }()
//    
//    private let stateLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 24, weight: .medium)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.text = "Work"
//        return label
//    }()
//    
//    private lazy var pomodoroCirclesStack: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .horizontal
//        stack.spacing = 10
//        stack.distribution = .fillEqually
//        return stack
//    }()
//    
//    private lazy var buttonStack: UIStackView = {
//        let stack = UIStackView(arrangedSubviews: [startButton, pauseButton, resetButton])
//        stack.axis = .horizontal
//        stack.spacing = 16
//        stack.distribution = .fillEqually
//        return stack
//    }()
//    
//    // MARK: - Properties
//    private let model = HomeViewControllerModel()
//    private var circleViews: [UIView] = []
//    private let maxCircles = 4 // Максимальное количество кружков перед длинным перерывом
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupConstraints()
//        setupActions()
//        bindModel()
//        setupPomodoroCircles()
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        view.addSubview(timeLabel)
//        view.addSubview(stateLabel)
//        view.addSubview(progressView)
//        view.addSubview(pomodoroCirclesStack)
//        view.addSubview(buttonStack)
//        
//        updateUI(for: model.currentState)
//    }
//    
//    private func setupConstraints() {
//        [timeLabel, stateLabel, progressView, pomodoroCirclesStack, buttonStack].forEach {
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//        
//        NSLayoutConstraint.activate([
//            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            timeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
//            
//            stateLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
//            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            pomodoroCirclesStack.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 24),
//            pomodoroCirclesStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            pomodoroCirclesStack.heightAnchor.constraint(equalToConstant: 20),
//            pomodoroCirclesStack.widthAnchor.constraint(equalToConstant: CGFloat(maxCircles * 20 + (maxCircles - 1) * 10)),
//            
//            progressView.topAnchor.constraint(equalTo: pomodoroCirclesStack.bottomAnchor, constant: 24),
//            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
//            progressView.heightAnchor.constraint(equalToConstant: 8),
//            
//            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
//            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
//            buttonStack.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//    
//    private func setupActions() {
//        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
//        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
//        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
//    }
//    
//    private func bindModel() {
//        model.timerUpdated = { [weak self] timeString in
//            self?.timeLabel.text = timeString
//        }
//        
//        model.stateChanged = { [weak self] state in
//            self?.updateUI(for: state)
//            
//            // Обновляем кружочки при завершении работы
//            if case .work = state {
//                self?.updatePomodoroCircles()
//            }
//        }
//        
//        model.progressUpdated = { [weak self] progress in
//            self?.progressView.setProgress(Float(progress), animated: true)
//        }
//    }
    
//    private func setupPomodoroCircles() {
//        // Очищаем предыдущие кружочки
//        pomodoroCirclesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        circleViews.removeAll()
//        
//        // Создаём кружочки
//        for _ in 0..<maxCircles {
//            let circle = UIView()
//            circle.backgroundColor = .systemGray4
//            circle.layer.cornerRadius = 10
//            circle.clipsToBounds = true
//            NSLayoutConstraint.activate([
//                circle.widthAnchor.constraint(equalToConstant: 20),
//                circle.heightAnchor.constraint(equalToConstant: 20)
//            ])
//            pomodoroCirclesStack.addArrangedSubview(circle)
//            circleViews.append(circle)
//        }
//    }
//    
//    private func updatePomodoroCircles() {
//        let completedPomodoros = model.cyclesCompleted % maxCircles
//        
//        // Обновляем цвет кружочков
//        for (index, circle) in circleViews.enumerated() {
//            UIView.animate(withDuration: 0.3) {
//                circle.backgroundColor = index < completedPomodoros ? .systemBlue : .systemGray4
//            }
//        }
//        
//        // Если все кружочки заполнены - сбрасываем после длинного перерыва
//        if completedPomodoros == 0 && model.cyclesCompleted > 0 {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                self.setupPomodoroCircles()
//            }
//        }
//    }
//    
//    // MARK: - Actions
//    @objc private func startButtonTapped() {
//        model.startTimer()
//    }
//    
//    @objc private func pauseButtonTapped() {
//        model.pauseTimer()
//    }
//    
//    @objc private func resetButtonTapped() {
//        model.resetTimer()
//        setupPomodoroCircles()
//    }
//    
//    // MARK: - UI Updates
//    private func updateUI(for state: HomeViewControllerModel.TimerState) {
//        switch state {
//        case .work:
//            stateLabel.text = "Work"
//            progressView.progressTintColor = .systemBlue
//            view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
//        case .shortBreak:
//            stateLabel.text = "Short Break"
//            progressView.progressTintColor = .systemGreen
//            view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
//        case .longBreak:
//            stateLabel.text = "Long Break"
//            progressView.progressTintColor = .systemOrange
//            view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
//        case .paused:
//            stateLabel.text = "Paused"
//            progressView.progressTintColor = .systemGray
//            view.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
//        }
//    }
//}

//import Foundation
//
//class HomeViewController: UIViewController {
//    
//    // MARK: - Circle Animation Properties
//    private let circleLayer = CAShapeLayer()
//    private let backgroundCircleLayer = CAShapeLayer()
//    private var circleAnimation: CABasicAnimation?
//    private var circleResumedTime: CFTimeInterval = 0
//    
//    // Остальные свойства...
//    
//    private func setupCircle() {
//        let center = view.center
//        let radius: CGFloat = 150
//        let startAngle = -CGFloat.pi / 2
//        let endAngle = 2 * CGFloat.pi - CGFloat.pi / 2
//        
//        let circularPath = UIBezierPath(arcCenter: center,
//                                      radius: radius,
//                                      startAngle: startAngle,
//                                      endAngle: endAngle,
//                                      clockwise: true)
//        
//        // Background circle
//        backgroundCircleLayer.path = circularPath.cgPath
//        backgroundCircleLayer.fillColor = UIColor.clear.cgColor
//        backgroundCircleLayer.strokeColor = Resources.Color.separator.cgColor
//        backgroundCircleLayer.lineWidth = 30
//        backgroundCircleLayer.strokeEnd = 1
//        view.layer.addSublayer(backgroundCircleLayer)
//        
//        // Progress circle
//        circleLayer.path = circularPath.cgPath
//        circleLayer.fillColor = UIColor.clear.cgColor
//        circleLayer.strokeColor = Resources.Color.active.cgColor
//        circleLayer.lineWidth = 30
//        circleLayer.strokeEnd = 0
//        circleLayer.lineCap = .round
//        view.layer.addSublayer(circleLayer)
//    }
//    
//    private func startCircleAnimation(duration: TimeInterval) {
//        circleLayer.removeAllAnimations()
//        
//        let animation = CABasicAnimation(keyPath: "strokeEnd")
//        animation.fromValue = 0
//        animation.toValue = 1
//        animation.duration = duration
//        animation.fillMode = .forwards
//        animation.isRemovedOnCompletion = false
//        animation.timingFunction = CAMediaTimingFunction(name: .linear)
//        
//        // Сохраняем ссылку на анимацию
//        circleAnimation = animation
//        
//        // Запускаем анимацию с текущего прогресса
//        let timeOffset = duration * (1 - homeControllerModel.currentProgress)
//        animation.beginTime = CACurrentMediaTime() + timeOffset
//        animation.fromValue = homeControllerModel.currentProgress
//        animation.toValue = 1
//        
//        circleLayer.strokeEnd = CGFloat(homeControllerModel.currentProgress)
//        circleLayer.add(animation, forKey: "circleAnimation")
//    }
//    
//    private func pauseCircleAnimation() {
//        // Сохраняем текущий прогресс
//        circleResumedTime = circleLayer.convertTime(CACurrentMediaTime(), from: nil)
//        circleLayer.speed = 0
//    }
//    
//    private func resumeCircleAnimation() {
//        // Восстанавливаем анимацию с места паузы
//        let pausedTime = circleLayer.timeOffset
//        circleLayer.speed = 1
//        circleLayer.timeOffset = 0
//        circleLayer.beginTime = 0
//        let timeSincePause = circleLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
//        circleLayer.beginTime = timeSincePause
//    }
//    
//    private func resetCircleAnimation() {
//        circleLayer.removeAllAnimations()
//        circleLayer.strokeEnd = 0
//        circleAnimation = nil
//        circleResumedTime = 0
//    }
//    
//    // Обновленный обработчик кнопки
//    @objc private func startButtonTapped() {
//        if isActive {
//            // Пауза
//            homeControllerModel.pauseTimer()
//            pauseCircleAnimation()
//            startButton.setTitle(Resources.Text.Label.start, for: .normal)
//        } else {
//            // Старт/продолжение
//            homeControllerModel.startTimer()
//            
//            if circleAnimation != nil {
//                resumeCircleAnimation()
//            } else {
//                let duration = TimeInterval(homeControllerModel.totalDurationForCurrentState)
//                startCircleAnimation(duration: duration)
//            }
//            
//            startButton.setTitle(Resources.Text.Label.pause, for: .normal)
//        }
//        
//        isActive.toggle()
//    }
//    
//    // Обновленный сброс
//    @objc private func resetButtonTapped() {
//        homeControllerModel.resetTimer()
//        resetCircleAnimation()
//        
//        if isActive {
//            startButton.setTitle(Resources.Text.Label.start, for: .normal)
//            isActive = false
//        }
//    }
//}

//enum TimerState {
//    case work
//    case shortBreak
//    case longBreak
//    case paused
//    case stopped
//}
//
//struct PomodoroSettings {
//    var workDuration: TimeInterval // в минутах
//    var shortBreakDuration: TimeInterval
//    var longBreakDuration: TimeInterval
//    var pomodorosBeforeLongBreak: Int
//    
//    static let `default` = PomodoroSettings(
//        workDuration: 1,
//        shortBreakDuration: 5,
//        longBreakDuration: 15,
//        pomodorosBeforeLongBreak: 4
//    )
//}
//
//class PomodoroTimer {
//    private var timer: Timer?
//    private var totalSeconds: TimeInterval = 0
//    private(set) var timeRemaining: TimeInterval = 0
//    private(set) var timerState: TimerState = .stopped
//    private(set) var completedPomodoros = 0
//    
//    var settings: PomodoroSettings = .default
//    var onTick: ((TimeInterval) -> Void)?
//    var onStateChange: ((TimerState) -> Void)?
//    var onPomodoroComplete: (() -> Void)?
//    
//    init() {
//        reset()
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
//        onStateChange?(timerState)
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
//        reset()
//        onStateChange?(timerState)
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
//        onStateChange?(timerState)
//        onTick?(timeRemaining)
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            
//            if self.timeRemaining > 0 {
//                self.timeRemaining -= 1
//                self.onTick?(self.timeRemaining)
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
//            onPomodoroComplete?()
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
//    private func reset() {
//        timeRemaining = settings.workDuration * 60
//        totalSeconds = settings.workDuration * 60
//    }
//    
//    // Форматирование времени для отображения
//    func formattedTime() -> String {
//        let minutes = Int(timeRemaining) / 60
//        let seconds = Int(timeRemaining) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//    // Прогресс таймера (от 0 до 1)
//    func progress() -> Double {
//        guard totalSeconds > 0 else { return 0 }
//        return 1 - (timeRemaining / totalSeconds)
//    }
//}
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
