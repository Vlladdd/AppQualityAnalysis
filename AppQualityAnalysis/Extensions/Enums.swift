//
//  Enums.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 26.05.2022.
//

import Foundation

//MARK: - Some useful enums

enum FindUser {
    
    case wrongPassword
    case success
    
}

enum UpdateUser {
    
    case wrongNickname
    case success
    case failure
    
}

enum Result {
    
    case good
    case notBad
    case bad
    
}

enum OriginOfData: Equatable {
    
    case database
    case appStore
    case report
    case failure(String)
    
}
