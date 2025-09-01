//
//  HomeViewController.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - UI Elements
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 64, weight: .bold)
        label.textColor = Resouces.Color.titleColor
        label.textAlignment = .center
        label.text = "25:00"
        return label
    }()
    
    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = .systemGray5
        view.progressTintColor = .systemBlue
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private let startButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Resouces.Text.Label.start
        config.baseBackgroundColor = .systemGreen
        config.cornerStyle = .large
        return UIButton(configuration: config)
    }()
    
    private let pauseButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Resouces.Text.Label.pause
        config.baseBackgroundColor = .systemOrange
        config.cornerStyle = .large
        return UIButton(configuration: config)
    }()
    
    private let resetButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Resouces.Text.Label.reset
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .large
        return UIButton(configuration: config)
    }()
    
    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "Work"
        return label
    }()
    
    private lazy var pomodoroCirclesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [startButton, pauseButton, resetButton])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    // MARK: - Properties
    private let model = HomeViewControllerModel()
    var modelInstance: HomeViewControllerModel {
        return model
    }

    private var circleViews: [UIView] = []
    private let maxCircle = PomodoroSettings.default.pomodorosBeforeLongBreak
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        bindModel()
        setupPomodoroCircles()
        model.requestNotificationPermissions()
        setupObservers()

        if let endDate = UserDefaults.standard.object(forKey: "pomodoroEndDate") as? Date,
           let stateRaw = UserDefaults.standard.string(forKey: "currentState"),
           let restoredState = HomeViewControllerModel.TimerState(rawValue: stateRaw) {

            model.currentState = restoredState
            let wasActive = UserDefaults.standard.bool(forKey: "isTimerActive")

            if wasActive {
                // 🔹 Таймер шёл → восстанавливаем с endDate
                model.sessionEndDate = endDate
                switch restoredState {
                case .work:
                    model.sessionStartDate = endDate.addingTimeInterval(-model.settings.workDuration * 60)
                case .shortBreak:
                    model.sessionStartDate = endDate.addingTimeInterval(-model.settings.shortBreakDuration * 60)
                case .longBreak:
                    model.sessionStartDate = endDate.addingTimeInterval(-model.settings.longBreakDuration * 60)
                case .paused:
                    break
                }
                model.recalculateTimeRemaining()
                model.handleAppWillEnterForeground()
            } else {
                // 🔹 Таймер не активен → показываем полный прогресс
                switch restoredState {
                case .work:
                    model.timeRemaining = Int(model.settings.workDuration * 60)
                case .shortBreak:
                    model.timeRemaining = Int(model.settings.shortBreakDuration * 60)
                case .longBreak:
                    model.timeRemaining = Int(model.settings.longBreakDuration * 60)
                case .paused:
                    break
                }
                model.sessionStartDate = nil
                model.sessionEndDate = nil
                model.updateDisplay()
                updateUI(for: restoredState)
            }
        }
    }



//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupActions()
//        bindModel()
//        setupPomodoroCircles()
//        model.requestNotificationPermissions()
//        setupObservers()
//        
//        // Восстановление состояния после запуска
//        if let endDate = UserDefaults.standard.object(forKey: "pomodoroEndDate") as? Date {
//            let remaining = Int(endDate.timeIntervalSinceNow)
//            if remaining > 0 {
//                model.recalculateTimeRemaining()
//                model.handleAppWillEnterForeground()
//            }
//        }
//    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground() {
        model.handleAppWillEnterForeground()
    }
    
    private func setupObservers2() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        model.saveStateBeforeBackground()
    }

    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addView(pomodoroCirclesStack)
        view.addView(timeLabel)
        view.addView(stateLabel)
        view.addView(progressView)
        view.addView(buttonStack)
        
        // Настройка цвета для разных состояний
        updateUI(for: model.currentState)
        
        NSLayoutConstraint.activate([
            
            pomodoroCirclesStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 240),
            pomodoroCirclesStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pomodoroCirclesStack.heightAnchor.constraint(equalToConstant: 20),
            pomodoroCirclesStack.widthAnchor.constraint(equalToConstant: CGFloat(maxCircle * 20 + (maxCircle - 1) * 10)),
            
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            stateLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressView.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 32),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    private func bindModel() {
        model.timerUpdated = { [weak self] timeString in
            DispatchQueue.main.async {
                self?.timeLabel.text = timeString
            }
        }

        model.stateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(for: state)
                if case .work = state {
                    self?.updatePomodoroCircles()
                }
            }
        }

        model.progressUpdated = { [weak self] progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.progressView.setProgress(Float(progress), animated: progress != 0)
            }
        }

        model.timerReset = { [weak self] in
            DispatchQueue.main.async {
                self?.progressView.setProgress(1.0, animated: false)
                self?.timeLabel.text = "00:00"
            }
        }
    }

    private func setupPomodoroCircles() {
        pomodoroCirclesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        circleViews.removeAll()
        
        for _ in 0..<maxCircle {
            let circle = UIView()
            circle.backgroundColor = Resouces.Color.active
            circle.layer.cornerRadius = 10
            circle.clipsToBounds = true
            
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: 20),
                circle.heightAnchor.constraint(equalToConstant: 20)
            ])
            pomodoroCirclesStack.addArrangedSubview(circle)
            circleViews.append(circle)
        }
    }
    
    private func resetPomodoroCircles() {
        for circle in circleViews {
            UIView.animate(withDuration: 0.3) {
                circle.backgroundColor = .systemGray4
            }
        }
    }

    
    private func updatePomodoroCircles() {
        let completedPomodoros = model.cyclesCompleted % maxCircle
        
        for (index, circle) in circleViews.enumerated() {
            UIView.animate(withDuration: 0.3) {
                UIView.animate(withDuration: 0.3) {
                    circle.backgroundColor = index < completedPomodoros ? .systemBlue : .systemGray4
                }
            }
            
            // Если все кружочки заполнены - сбрасываем после длинного перерыва
            if completedPomodoros == 0 && model.cyclesCompleted > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.setupPomodoroCircles()
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func startButtonTapped() {
        if model.currentState == .paused {
            model.resumeTimer() // только одно уведомление на оставшееся время
        } else {
            model.startTimer() // запускаем таймер и полную серию уведомлений
        }
    }
    
    @objc private func pauseButtonTapped() {
        model.pauseTimer()
//        model.cancelAllNotifications()

    }
    
    @objc private func resetButtonTapped() {
        model.resetTimer()
        resetPomodoroCircles()
    }
//    
//    @objc private func appDidEnterBackground() {
//        model.saveStateBeforeBackground()
//    }
    
    // MARK: - UI Updates
    private func updateUI(for state: HomeViewControllerModel.TimerState) {
        switch state {
        case .work:
            stateLabel.text = Resouces.Text.Label.work
            progressView.progressTintColor = .systemBlue
            view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        case .shortBreak:
            stateLabel.text = Resouces.Text.Label.shortBreak
            progressView.progressTintColor = .systemGreen
            view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        case .longBreak:
            stateLabel.text = Resouces.Text.Label.longBreak
            progressView.progressTintColor = .systemOrange
            view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        case .paused:
            stateLabel.text = Resouces.Text.Label.pause
            progressView.progressTintColor = .systemGray
            view.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        }
    }
}
