//
//  Extensions.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 26.05.2022.
//

import Foundation

//MARK: - Some useful extensions

extension String {
    
    var letters: String {
        return String(unicodeScalars.filter(CharacterSet.letters.contains))
    }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
}

extension Double {
    // Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
