//
//  HomeViewController.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit
import Foundation

class HomeViewController: UIViewController {
    
    var homeControllerModel = HomeViewControllerModel()
    
    var seconds = ""
    
    var isActive: Bool = false
    
    private let shape = CAShapeLayer()
    
    private var timer: Timer?
    
    private let sessionLabel: UILabel = {
        let label = UILabel()
        label.text = Resouces.Text.Label.session
        label.textColor = Resouces.Color.titleColor
        label.font = Resouces.Fonts.helveticaBold(size: 35)
        return label
    }()
    
    private var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = Resouces.Color.titleColor
        label.font = Resouces.Fonts.helveticaRegular(size: 35)
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.setTitle(Resouces.Text.Label.start, for: .normal)
        button.backgroundColor = Resouces.Color.button
        button.titleLabel?.font = Resouces.Fonts.helveticaBold(size: 27)
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.setTitle(Resouces.Text.Label.reset, for: .normal)
        button.backgroundColor = Resouces.Color.reset
        button.titleLabel?.font = Resouces.Fonts.helveticaBold(size: 27)
        return button
    }()
    
    
    override func viewDidLoad() {
        setupUI()
        setupViewModel()
        createСircle()
        addTarget()
        timerLabel.text = String(" Go")
        print(seconds)
        
    }
    
    private func addTarget() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    @objc func startButtonTapped() {
        homeControllerModel.startTimer()
        if isActive {
            startButton.setTitle(Resouces.Text.Label.start, for: .normal)
            startButton.backgroundColor = Resouces.Color.button
            isActive = false
            homeControllerModel.stopTimer()
            pauseCircleAnimation()
        } else {
            animationCircle()
            startButton.setTitle(Resouces.Text.Label.pause, for: .normal)
            startButton.backgroundColor = Resouces.Color.pause
            isActive = true
        }
    }
    
//    @objc func startButtonTapped() {
//        animationCircle()
//        homeControllerModel.startTimer()
//        if isActive {
//            startButton.setTitle(Resouces.Text.Label.start, for: .normal)
//            startButton.backgroundColor = Resouces.Color.button
//            isActive = false
//        } else {
//            homeControllerModel.stopTimer()
//            startButton.setTitle(Resouces.Text.Label.pause, for: .normal)
//            startButton.backgroundColor = Resouces.Color.pause
//            isActive = true
//        }
//    }
    
    @objc private func resetButtonTapped() {
        homeControllerModel.stopTimer()
        homeControllerModel.resetTimer()
        resetCircleAnimation()
    }
    
    private func createСircle() {
        let circle = UIBezierPath(arcCenter: view.center,
                                  radius: 150,
                                  startAngle: -(.pi / 2),
                                  endAngle: .pi * 2,
                                  clockwise: true)
        
        let trackShape = CAShapeLayer()
        trackShape.path = circle.cgPath
        trackShape.fillColor = UIColor.clear.cgColor
        trackShape.lineWidth = 30
        trackShape.strokeColor = Resouces.Color.separator.cgColor
        view.layer.addSublayer(trackShape)
        
        shape.path = circle.cgPath
        shape.lineWidth = 30
        shape.strokeColor = Resouces.Color.active.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeEnd = 0
        shape.lineCap = .round
        view.layer.addSublayer(shape)
    }
    
    private func animationCircle() {
        shape.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 0.8
        animation.duration = CFTimeInterval(homeControllerModel.duretionTimer)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        shape.add(animation, forKey: "animationCircle")
    }
    
    private func resetCircleAnimation() {
       // homeControllerModel.stopTimer()
        homeControllerModel.resetTimer()
        shape.removeAllAnimations()
        shape.strokeEnd = 0
    }
    
    private func pauseCircleAnimation() {
        shape.strokeEnd = 0.3
    }
    
    private func setupViewModel() {
        homeControllerModel.timerUpdated = { [weak self] timeString in
            self?.timerLabel.text = timeString
            print(timeString)
        }
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [resetButton, startButton])
        stackView.axis = .horizontal
        stackView.spacing = 30
        stackView.distribution = .fillEqually
        
        view.backgroundColor = Resouces.Color.background
        
        view.addView(sessionLabel)
        //view.addView(startButton)
        
        view.addView(stackView)
        view.addSubview(timerLabel)
        timerLabel.sizeToFit()
        timerLabel.setNeedsDisplay()
        timerLabel.center = view.center
        
        NSLayoutConstraint.activate([
            sessionLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80),
            sessionLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30),
        
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
}
