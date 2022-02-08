//
//  Review.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 07.11.2021.
//

import Foundation
import RealmSwift

class RealmReview: Object{
    @Persisted var text: String
    @Persisted var date: Date
    @Persisted var rating: Int
    @Persisted var version: String
    @Persisted var appID: String
}


struct Review: Equatable {
    var text: String?
    var date: Date?
    var rating: Int?
    var version: String?
    var appID: String?
    
    init(_ text: String, _ date: Date, _ rating: Int, _ version: String, _ appID: String){
        self.text = text
        self.date = date
        self.rating = rating
        self.version = version
        self.appID = appID
    }
    
    static func ==(lhs:Review, rhs:Review) -> Bool {
        return lhs.text == rhs.text
    }
}

