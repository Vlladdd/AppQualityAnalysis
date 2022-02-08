//
//  Metric.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 09.11.2021.
//

import Foundation
import RealmSwift

class RealmMetric: Object{
    @Persisted var name: String
    @Persisted var value: Double
    @Persisted var maxValue: Double
    @Persisted var report: Report!
}

struct Metric: Equatable{
    
    var name: String!
    var value: Double!
    var maxValue: Double!
    
    let realm = try! Realm()
    
    init(_ name: String, _ value: Double, _ maxValue: Double = 0.0){
        self.name = name
        self.value = value
        self.maxValue = maxValue
    }
    
    init() {
        
    }
    
    lazy var metrics = realm.objects(RealmMetric.self)
    var currentMetrics = [RealmMetric]()
    
    func createMetric(report: Report){
        try! realm.write {
            let metric = RealmMetric()
            metric.name = self.name
            metric.value = self.value
            metric.maxValue = self.maxValue
            metric.report = report
            realm.add(metric)
        }
    }
    
    mutating func findMetrics(report: Report){
        currentMetrics = [RealmMetric]()
        let findMetrics = metrics.where {
            $0.report == report
        }
        if findMetrics.isEmpty == false {
            for metric in findMetrics {
                currentMetrics.append(metric)
            }
        }
    }
    
    mutating func deleteAll() {
        try! realm.write {
            realm.delete(metrics)
        }
    }
    
    static func ==(lhs:Metric, rhs:Metric) -> Bool {
        return lhs.name == rhs.name
    }
}
