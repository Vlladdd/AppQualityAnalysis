//
//  ReportModel.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 08.12.2021.
//

import Foundation
import RealmSwift

//MARK: - Report Blank

//struct that represents copy of Report object in Realm
struct ReportBlank: Equatable{

    var name: String
    var appID: String
    var date: Date
    var metrics: [MetricBlank] = []
    
    init(name: String, appID: String, date: Date, metrics: [MetricBlank] = []){
        self.name = name
        self.appID = appID
        self.date = date
        self.metrics = metrics
    }
    
    static func == (lhs: ReportBlank, rhs: ReportBlank) -> Bool {
        lhs.name == rhs.name
    }
    
}

//MARK: - Report

//class that represents Report object in Realm
class Report: Object {
    @Persisted var name: String
    @Persisted var appID: String
    @Persisted var date: Date
    @Persisted var metrics: List<Metric>
    @Persisted(originProperty: "reports") var users: LinkingObjects<User>
}

//MARK: - Model of Report

//class that represents model of Report
class ReportModel {
    
    //MARK: - Properties
    
    var currentReport: ReportBlank?
    
    //MARK: - Functions
    
    func createReport(name: String, appID: String, date: Date, user: UserBlank){
        let realm = try! Realm()
        currentReport = ReportBlank(name: name, appID: appID, date: date)
        let users = realm.objects(User.self)
        let findUsers = users.where {
            $0.nickname == user.nickname
        }
        if findUsers.count == 1 {
            try! realm.write {
                let report = Report()
                report.name = name
                report.appID = appID
                report.date = date
                findUsers.first!.reports.append(report)
                realm.add(report)
            }
        }
    }
    
    func findReport(name: String, username: String) -> Bool{
        let realm = try! Realm()
        let reports = realm.objects(Report.self)
        let findReports = reports.where {
            $0.name == name && $0.users.nickname == username
        }
        if findReports.count == 1 {
            currentReport = ReportBlank(name: findReports.first!.name, appID: findReports.first!.appID, date: findReports.first!.date)
            return true
        }
        else {
            return false
        }
    }
    
    func deleteReport(name: String, username: String){
        let realm = try! Realm()
        let reports = realm.objects(Report.self)
        let findReports = reports.where {
            $0.name == name && $0.users.nickname == username
        }
        if findReports.count == 1 {
            try! realm.write {
                realm.delete(findReports.first!)
            }
        }
    }

    func getReportsNames(username: String) -> [String]{
        let realm = try! Realm()
        let reports = realm.objects(Report.self)
        var names = [String]()
        let findReports = reports.where {
            $0.users.nickname == username
        }
        for report in findReports {
            names.append(report.name)
        }
        return names.sorted(by: <)
    }
}
