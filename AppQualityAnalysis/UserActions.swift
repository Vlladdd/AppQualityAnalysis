//
//  UserActions.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 07.12.2021.
//

import Foundation
import RealmSwift

class Action: Object {
    @Persisted var user: User!
    @Persisted var date: Date
    @Persisted var action: String
}

class Actions {
    let realm = try! Realm()
    lazy var actions = realm.objects(Action.self)
    var currentUserActions = [Action]()
    
    func createAction(user: User, date: Date, userAction: String){
        try! realm.write {
            let action = Action()
            action.user = user
            action.date = date
            action.action = userAction
            realm.add(action)
        }
    }
    
    func findActions(user: User){
        let findActions = actions.where {
            $0.user == user
        }
        if findActions.isEmpty == false {
            for action in findActions {
                currentUserActions.append(action)
            }
        }
    }
    
}
