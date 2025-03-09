//
//  Resouces.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit

enum Resouces {
    
    enum Color {
        static let background = UIColor(hexString: "#121424")
        static let button = UIColor(hexString: "#49B655")
        static let titleColor = UIColor(hexString: "#FFFFFF")
        static let separator = UIColor(hexString: "#E8ECEF")
        static let active = UIColor(hexString: "#437BFE")
    }
    
    enum Text {
        
        enum Label {
            static let session = Bundle.main.localizedString(forKey: "сессия", value: "", table: "Localizable")
            static let start = Bundle.main.localizedString(forKey: "старт", value: "", table: "Localizable")
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
