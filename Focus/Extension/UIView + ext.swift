//
//  UIView + ext.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit

extension UIView {
    
    func addView(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
}
