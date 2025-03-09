//
//  HomeViewControllerModel.swift
//  Focus
//
//  Created by Максим Зыкин on 08.03.2025.
//

import Foundation

class HomeViewControllerModel {
    
   private let timer = Timer()
    
    var duretionTimer = 15
    
    func timerAction(){
        if duretionTimer > 0 {
            duretionTimer -= 1
            print(duretionTimer)
        }
    }
}

