//
//  HomeViewController.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit

class HomeViewController: UIViewController {
    
    var homeControllerModel: HomeViewControllerModel = .init()
    
    private let shape = CAShapeLayer()
    
    private var timer = Timer()
    
    private let sessionLabel: UILabel = {
        let label = UILabel()
        label.text = Resouces.Text.Label.session
        label.textColor = Resouces.Color.titleColor
        label.font = Resouces.Fonts.helveticaBold(size: 35)
        return label
    }()
    
    private var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00"
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
    
    override func viewDidLoad() {
        setupUI()
        createСircle()
        addTarget()
        timerLabel.text = String(homeControllerModel.duretionTimer)
    }
    
    private func addTarget() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    @objc func startButtonTapped() {
        animationCircle()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    @objc func timerAction() {
        homeControllerModel.timerAction()
        timerLabel.text = String(homeControllerModel.duretionTimer)
        if homeControllerModel.duretionTimer == 0 {
            timer.invalidate()
        }
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
        view.layer.addSublayer(shape)
    }
    
    private func animationCircle() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 0.8
        animation.duration = CFTimeInterval(homeControllerModel.duretionTimer)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        shape.add(animation, forKey: "animation")
    }
    
    private func setupUI() {
        view.backgroundColor = Resouces.Color.background
        
        view.addView(sessionLabel)
        view.addView(startButton)
        view.addSubview(timerLabel)
        timerLabel.sizeToFit()
        timerLabel.center = view.center
        
        NSLayoutConstraint.activate([
            sessionLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80),
            sessionLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30),
            
            startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            startButton.widthAnchor.constraint(equalToConstant: 200),

        ])
    }
}
