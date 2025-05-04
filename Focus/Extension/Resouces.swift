//
//  Resouces.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit

let localizable = "Localizable"

enum Resouces {
    
    enum Color {
        static let background = UIColor(hexString: "#121424")
        static let button = UIColor(hexString: "#49B655")
        static let reset = UIColor(hexString: "#ff033e")
        static let pause = UIColor(hexString: "#ffb841")
        static let titleColor = UIColor(hexString: "#FFFFFF")
        static let separator = UIColor(hexString: "#E8ECEF")
        static let active = UIColor(hexString: "#437BFE")
    }
    
    enum Text {
    
        enum Label {
            static let session = Bundle.main.localizedString(forKey: "сессия", value: "", table: localizable)
            static let start = Bundle.main.localizedString(forKey: "старт", value: "", table: localizable)
            static let pause = Bundle.main.localizedString(forKey: "пауза", value: "", table: localizable)
            static let reset = Bundle.main.localizedString(forKey: "перезапустить", value: "", table: localizable)
            static let work = Bundle.main.localizedString(forKey: "работа", value: "", table: localizable)
            static let shortBreak = Bundle.main.localizedString(forKey: "короткий перерыв", value: "", table: localizable)
            static let longBreak = Bundle.main.localizedString(forKey: "длинный перерыв", value: "", table: localizable)
            static let notificationBody = Bundle.main.localizedString(forKey: "Время вышло ⏰", value: "", table: localizable)
        }
    }
    
    enum Fonts {
        static func helveticaRegular(size: CGFloat) -> UIFont {
            UIFont(name: "Helvetica", size: size) ?? UIFont()
        }
        
        static func helveticaBold(size: CGFloat) -> UIFont {
            UIFont(name: "Helvetica Bold", size: size) ?? UIFont()
        }
    }
}
