//
//  Reports.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 08.12.2021.
//

import Foundation
import RealmSwift

class Report: Object {
    @Persisted var name: String
    @Persisted var appID: String
    @Persisted var date: Date
    @Persisted var user: User!
}

class Reports {
    let realm = try! Realm()
    lazy var reports = realm.objects(Report.self)
    var currentReport: Report!
    
    func createReport(name: String, appID: String, date: Date, user: User){
        try! realm.write {
            let report = Report()
            report.name = name
            report.appID = appID
            report.date = date
            report.user = user
            currentReport = report
            realm.add(report)
        }
    }
    
    func findReport(name: String) -> Bool{
        let findReport = reports.where {
            $0.name == name
        }
        if findReport.isEmpty == false {
            currentReport = findReport[0]
            return true
        }
        else {
            return false
        }
    }

    
    func getReportsNames() -> [String]{
        var names = [String]()
        for report in reports {
            names.append(report.name)
        }
        return names
    }
}
