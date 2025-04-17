//
//  еуые.swift
//  Focus
//
//  Created by Максим Зыкин on 28.03.2025.
//

import Foundation
import UIKit

import UIKit

class PomodoroViewController: UIViewController {
    private let pomodoroTimer = PomodoroTimer()
    
    // UI элементы
    private let stateLabel = UILabel()
    private let timeLabel = UILabel()
    private let progressView = CircularProgressView()
    private let startButton = UIButton()
    private let pauseButton = UIButton()
    private let stopButton = UIButton()
    private let pomodorosLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimerCallbacks()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // State Label
        stateLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        stateLabel.textAlignment = .center
        stateLabel.text = "Готов к работе"
        
        // Time Label
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.text = pomodoroTimer.formattedTime()
        
        // Progress View
        progressView.lineWidth = 10
        progressView.trackColor = .systemGray5
        progressView.progressColor = .systemGray
        
        // Buttons
        startButton.setTitle("Начать работу", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startWork), for: .touchUpInside)
        
        pauseButton.setTitle("Пауза", for: .normal)
        pauseButton.backgroundColor = .systemBlue
        pauseButton.layer.cornerRadius = 10
        pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
        pauseButton.isHidden = true
        
        stopButton.setTitle("Стоп", for: .normal)
        stopButton.backgroundColor = .systemRed
        stopButton.layer.cornerRadius = 10
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        stopButton.isHidden = true
        
        // Pomodoros Label
        pomodorosLabel.font = UIFont.systemFont(ofSize: 18)
        pomodorosLabel.textAlignment = .center
        pomodorosLabel.text = "Завершено помодоро: 0"
        
        // Stack Views
        let buttonsStack = UIStackView(arrangedSubviews: [startButton, pauseButton, stopButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 20
        buttonsStack.distribution = .fillEqually
        
        let mainStack = UIStackView(arrangedSubviews: [stateLabel, progressView, timeLabel, buttonsStack, pomodorosLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 30
        mainStack.alignment = .center
        
        view.addSubview(mainStack)
        
        // Constraints
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            progressView.widthAnchor.constraint(equalToConstant: 300),
            progressView.heightAnchor.constraint(equalTo: progressView.widthAnchor),
            
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            pauseButton.heightAnchor.constraint(equalTo: startButton.heightAnchor),
            stopButton.heightAnchor.constraint(equalTo: startButton.heightAnchor)
        ])
    }
    
    private func setupTimerCallbacks() {
        pomodoroTimer.onTick = { [weak self] timeRemaining in
            DispatchQueue.main.async {
                self?.timeLabel.text = self?.pomodoroTimer.formattedTime()
                let progress = self?.pomodoroTimer.progress() ?? 0
                self?.progressView.setProgress(progress, animated: true)
            }
        }
        
        pomodoroTimer.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(for: state)
            }
        }
        
        pomodoroTimer.onPomodoroComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.pomodorosLabel.text = "Завершено помодоро: \(self?.pomodoroTimer.completedPomodoros ?? 0)"
                self?.playCompletionSound()
            }
        }
    }
    
    private func updateUI(for state: TimerState) {
        switch state {
        case .work:
            stateLabel.text = "Работа"
            progressView.progressColor = .systemRed
            startButton.isHidden = true
            pauseButton.isHidden = false
            stopButton.isHidden = false
            pauseButton.setTitle("Пауза", for: .normal)
            
        case .shortBreak:
            stateLabel.text = "Короткий перерыв"
            progressView.progressColor = .systemGreen
            
        case .longBreak:
            stateLabel.text = "Длинный перерыв"
            progressView.progressColor = .systemGreen
            
        case .paused:
            stateLabel.text = "Пауза"
            pauseButton.setTitle("Продолжить", for: .normal)
            
        case .stopped:
            stateLabel.text = "Готов к работе"
            progressView.progressColor = .systemGray
            startButton.isHidden = false
            pauseButton.isHidden = true
            stopButton.isHidden = true
            progressView.setProgress(0, animated: false)
            timeLabel.text = pomodoroTimer.formattedTime()
        }
    }
    
    private func playCompletionSound() {
        // Здесь можно добавить воспроизведение звука
        // Например, системный звук:
    }
    
    // MARK: - Actions
    
    @objc private func startWork() {
        pomodoroTimer.startWork()
    }
    
    @objc private func togglePause() {
        pomodoroTimer.togglePause()
    }
    
    @objc private func stop() {
        pomodoroTimer.stop()
    }
}

// Кастомное view для кругового прогресса
class CircularProgressView: UIView {
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    var lineWidth: CGFloat = 10 {
        didSet {
            updateLayers()
        }
    }
    
    var progressColor: UIColor = .systemBlue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor: UIColor = .systemGray5 {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    private var progress: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
    }
    
    private func updateLayers() {
        trackLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height)/2 - lineWidth/2
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 3 * CGFloat.pi / 2,
            clockwise: true
        )
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = progress
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = progress
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.strokeEnd = progress
            progressLayer.add(animation, forKey: "animateProgress")
        } else {
            progressLayer.strokeEnd = progress
        }
    }
}

//class PomodoroViewController: UIViewController {
//    private let viewModel = PomodoroTimerViewModel()
//    
//    // UI элементы
//    private let stateLabel = UILabel()
//    private let timeLabel = UILabel()
//    private let progressView = CircularProgressView()
//    private let startButton = UIButton()
//    private let pauseButton = UIButton()
//    private let stopButton = UIButton()
//    private let pomodorosLabel = UILabel()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupViewModel()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        
//        // State Label
//        stateLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
//        stateLabel.textAlignment = .center
//        stateLabel.text = "Готов к работе"
//        
//        // Time Label
//        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
//        timeLabel.textAlignment = .center
//        timeLabel.text = "25:00"
//        
//        // Progress View
//        progressView.lineWidth = 10
//        progressView.trackColor = .systemGray5
//        progressView.progressColor = .systemGray
//        
//        // Buttons
//        startButton.setTitle("Начать работу", for: .normal)
//        startButton.backgroundColor = .systemGreen
//        startButton.layer.cornerRadius = 10
//        startButton.addTarget(self, action: #selector(startWork), for: .touchUpInside)
//        
//        pauseButton.setTitle("Пауза", for: .normal)
//        pauseButton.backgroundColor = .systemBlue
//        pauseButton.layer.cornerRadius = 10
//        pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
//        pauseButton.isHidden = true
//        
//        stopButton.setTitle("Стоп", for: .normal)
//        stopButton.backgroundColor = .systemRed
//        stopButton.layer.cornerRadius = 10
//        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
//        stopButton.isHidden = true
//        
//        // Pomodoros Label
//        pomodorosLabel.font = UIFont.systemFont(ofSize: 18)
//        pomodorosLabel.textAlignment = .center
//        pomodorosLabel.text = "Завершено помодоро: 0"
//        
//        // Stack Views
//        let buttonsStack = UIStackView(arrangedSubviews: [startButton, pauseButton, stopButton])
//        buttonsStack.axis = .horizontal
//        buttonsStack.spacing = 20
//        buttonsStack.distribution = .fillEqually
//        
//        let mainStack = UIStackView(arrangedSubviews: [stateLabel, progressView, timeLabel, buttonsStack, pomodorosLabel])
//        mainStack.axis = .vertical
//        mainStack.spacing = 30
//        mainStack.alignment = .center
//        
//        view.addSubview(mainStack)
//        
//        // Constraints
//        mainStack.translatesAutoresizingMaskIntoConstraints = false
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            
//            progressView.widthAnchor.constraint(equalToConstant: 300),
//            progressView.heightAnchor.constraint(equalTo: progressView.widthAnchor),
//            
//            startButton.widthAnchor.constraint(equalToConstant: 150),
//            startButton.heightAnchor.constraint(equalToConstant: 50),
//            pauseButton.heightAnchor.constraint(equalTo: startButton.heightAnchor),
//            stopButton.heightAnchor.constraint(equalTo: startButton.heightAnchor)
//        ])
//    }
//    
//    private func setupViewModel() {
//        viewModel.onTimeUpdated = { [weak self] timeString in
//            self?.timeLabel.text = timeString
//        }
//        
//        viewModel.onStateUpdated = { [weak self] state in
//            self?.updateUI(for: state)
//        }
//        
//        viewModel.onPomodorosUpdated = { [weak self] count in
//            self?.pomodorosLabel.text = "Завершено помодоро: \(count)"
//        }
//        
//        viewModel.onProgressUpdated = { [weak self] progress in
//            self?.progressView.setProgress(progress, animated: true)
//        }
//    }
//    
//    private func updateUI(for state: TimerState) {
//        switch state {
//        case .work:
//            stateLabel.text = "Работа"
//            progressView.progressColor = .systemRed
//            startButton.isHidden = true
//            pauseButton.isHidden = false
//            stopButton.isHidden = false
//            pauseButton.setTitle("Пауза", for: .normal)
//            
//        case .shortBreak:
//            stateLabel.text = "Короткий перерыв"
//            progressView.progressColor = .systemGreen
//            
//        case .longBreak:
//            stateLabel.text = "Длинный перерыв"
//            progressView.progressColor = .systemGreen
//            
//        case .paused:
//            stateLabel.text = "Пауза"
//            pauseButton.setTitle("Продолжить", for: .normal)
//            
//        case .stopped:
//            stateLabel.text = "Готов к работе"
//            progressView.progressColor = .systemGray
//            startButton.isHidden = false
//            pauseButton.isHidden = true
//            stopButton.isHidden = true
//            progressView.setProgress(0, animated: false)
//        }
//    }
//    
//    // MARK: - Actions
//    
//    @objc private func startWork() {
//        viewModel.startWork()
//    }
//    
//    @objc private func togglePause() {
//        viewModel.togglePause()
//    }
//    
//    @objc private func stop() {
//        viewModel.stop()
//    }
//}
//
//// Кастомное view для кругового прогресса
//class CircularProgressView: UIView {
//    private var progressLayer = CAShapeLayer()
//    private var trackLayer = CAShapeLayer()
//    
//    var lineWidth: CGFloat = 10 {
//        didSet {
//            updateLayers()
//        }
//    }
//    
//    var progressColor: UIColor = .systemBlue {
//        didSet {
//            progressLayer.strokeColor = progressColor.cgColor
//        }
//    }
//    
//    var trackColor: UIColor = .systemGray5 {
//        didSet {
//            trackLayer.strokeColor = trackColor.cgColor
//        }
//    }
//    
//    private var progress: CGFloat = 0
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayers()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayers()
//    }
//    
//    private func setupLayers() {
//        layer.addSublayer(trackLayer)
//        layer.addSublayer(progressLayer)
//        
//        trackLayer.fillColor = UIColor.clear.cgColor
//        trackLayer.strokeColor = trackColor.cgColor
//        trackLayer.lineWidth = lineWidth
//        trackLayer.lineCap = .round
//        
//        progressLayer.fillColor = UIColor.clear.cgColor
//        progressLayer.strokeColor = progressColor.cgColor
//        progressLayer.lineWidth = lineWidth
//        progressLayer.lineCap = .round
//        progressLayer.strokeEnd = 0
//    }
//    
//    private func updateLayers() {
//        trackLayer.lineWidth = lineWidth
//        progressLayer.lineWidth = lineWidth
//        
//        let center = CGPoint(x: bounds.midX, y: bounds.midY)
//        let radius = min(bounds.width, bounds.height)/2 - lineWidth/2
//        let path = UIBezierPath(
//            arcCenter: center,
//            radius: radius,
//            startAngle: -CGFloat.pi / 2,
//            endAngle: 3 * CGFloat.pi / 2,
//            clockwise: true
//        )
//        
//        trackLayer.path = path.cgPath
//        progressLayer.path = path.cgPath
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        updateLayers()
//    }
//    
//    func setProgress(_ progress: CGFloat, animated: Bool) {
//        self.progress = progress
//        
//        if animated {
//            let animation = CABasicAnimation(keyPath: "strokeEnd")
//            animation.fromValue = progressLayer.strokeEnd
//            animation.toValue = progress
//            animation.duration = 0.3
//            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//            progressLayer.strokeEnd = progress
//            progressLayer.add(animation, forKey: "animateProgress")
//        } else {
//            progressLayer.strokeEnd = progress
//        }
//    }
//}
