//
//  UserModel.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 04.12.2021.
//

import Foundation
import RealmSwift
import RNCryptor

//MARK: - User Blank

//struct that represents copy of User object in Realm
struct UserBlank: Equatable{

    var nickname: String
    var password: String
    var passwordKey: String
    var name: String?
    var date: Date?
    var actions: [ActionBlank] = []
    
    init(nickname: String, password: String, passwordKey: String, name: String? = nil, date: Date? = nil, actions: [ActionBlank] = []){
        self.nickname = nickname
        self.password = password
        self.passwordKey = passwordKey
        self.name = name
        self.date = date
        self.actions = actions
    }
    
    static func == (lhs: UserBlank, rhs: UserBlank) -> Bool {
        lhs.nickname == rhs.nickname
    }
    
}

//MARK: - Action Blank

//struct that represents copy of User`s action object in Realm
struct ActionBlank{
    
    var date: Date
    var action: String
    
    init(date: Date, action: String){
        self.date = date
        self.action = action
    }
}

//MARK: - User

//class that represents User object in Realm
class User: Object {
    @Persisted var nickname: String
    @Persisted var password: String
    @Persisted var passwordKey: String
    @Persisted var name: String?
    @Persisted var date: Date?
    @Persisted var actions: List<Action>
    @Persisted var reports: List<Report>
}

//MARK: - Action

//class that represents User`s action object in Realm
class Action: EmbeddedObject {
    @Persisted var date: Date
    @Persisted var action: String
}

//MARK: - Model of User

//class that represents model of User
class UserModel {
    
    //MARK: - Properties
    
    var currentUser: UserBlank?

    //MARK: - Functions
    
    //MARK: - User CRUD
    
    //gets currentUser or creates new one if user not exist
    func findUser(nickname: String, password: String) -> FindUser{
        let realm = try! Realm()
        let users = realm.objects(User.self)
        let findUsers = users.where {
            $0.nickname == nickname
        }
        if findUsers.count == 1 {
            currentUser = UserBlank(nickname: findUsers.first!.nickname, password: findUsers.first!.password, passwordKey: findUsers.first!.passwordKey, name: findUsers.first!.name, date: findUsers.first!.date, actions: findUsers.first!.actions.map({ActionBlank(date: $0.date, action: $0.action)}))
            if checkPassword(password: password) {
                createAction(date: Date(), userAction: "Authorization completed")
                return .success
            }
            else {
                return .wrongPassword
            }
        }
        else {
            createUser(nickname: nickname, password: password)
            return .success
        }
    }
    
    private func createUser(nickname: String, password: String){
        let realm = try! Realm()
        try! realm.write {
            let user = User()
            user.nickname = nickname
            user.passwordKey = generateEncryptionKey(withPassword: password)
            user.password = encryptMessage(message: password, encryptionKey: user.passwordKey)
            currentUser = UserBlank(nickname: nickname, password: user.password, passwordKey: user.passwordKey)
            realm.add(user)
        }
        createAction(date: Date(), userAction: "Account created")
    }
    
    private func checkPassword(password: String) -> Bool{
        if let currentUser = currentUser, let decryptPassword = try? decryptMessage(encryptedMessage: currentUser.password, encryptionKey: currentUser.passwordKey), decryptPassword == password   {
            return true
        }
        else {
            return false
        }
    }
    
    func updateUser(nickname: String, password: String, name: String, date: Date?) -> UpdateUser{
        let realm = try! Realm()
        if let currentUser = currentUser {
            let users = realm.objects(User.self)
            let findUsers = users.where {
                $0.nickname == currentUser.nickname
            }
            if findUsers.count == 1 {
                try! realm.write {
                    findUsers.first!.passwordKey = generateEncryptionKey(withPassword: password)
                    findUsers.first!.password = encryptMessage(message: password, encryptionKey: findUsers[0].passwordKey)
                    findUsers.first!.name = name
                    if let date = date {
                        findUsers.first!.date = date
                    }
                    findUsers.first!.nickname = nickname
                }
                createAction(date: Date(), userAction: "Account information updated")
                let findUsers = users.where {
                    $0.nickname == nickname
                }
                self.currentUser = UserBlank(nickname: findUsers.first!.nickname, password: findUsers.first!.password, passwordKey: findUsers.first!.passwordKey, name: findUsers.first!.name, date: findUsers.first!.date, actions: findUsers.first!.actions.map({ActionBlank(date: $0.date, action: $0.action)}))
                return .success
            }
            else {
                return .wrongNickname
            }
        }
        return .failure
    }
    
    func deleteUser(){
        let realm = try! Realm()
        if let currentUser = currentUser {
            let users = realm.objects(User.self)
            let findUsers = users.where {
                $0.nickname == currentUser.nickname
            }
            if findUsers.count == 1 {
                for report in findUsers.first!.reports {
                    if report.users.count == 1 {
                        try! realm.write {
                            realm.delete(report)
                        }
                    }
                }
                try! realm.write {
                    realm.delete(findUsers.first!)
                }
            }
            self.currentUser = nil
        }
    }
    
    //MARK: - Action CRUD
    
    func createAction(date: Date, userAction: String){
        let realm = try! Realm()
        if let currentUser = currentUser {
            let action = Action()
            action.date = date
            action.action = userAction
            self.currentUser!.actions.append(ActionBlank(date: date, action: userAction))
            let users = realm.objects(User.self)
            let findUsers = users.where {
                $0.nickname == currentUser.nickname
            }
            if findUsers.count == 1 {
                try! realm.write {
                    findUsers.first!.actions.append(action)
                }
            }
        }
    }
    
    //MARK: - Encryption/Decryption
    
    private func encryptMessage(message: String, encryptionKey: String) -> String {
        let messageData = message.data(using: .utf8)!
        let cipherData = RNCryptor.encrypt(data: messageData, withPassword: encryptionKey)
        return cipherData.base64EncodedString()
    }
    
    func decryptMessage(encryptedMessage: String, encryptionKey: String) throws -> String {

        let encryptedData = Data.init(base64Encoded: encryptedMessage)!
        let decryptedData = try RNCryptor.decrypt(data: encryptedData, withPassword: encryptionKey)
        let decryptedString = String(data: decryptedData, encoding: .utf8)!

        return decryptedString
    }
    
    //we use key to encrypt/decrypt password
    private func generateEncryptionKey(withPassword password:String) -> String {
        let randomData = RNCryptor.randomData(ofLength: UserModelConstants.lengthOfEncryptionKey)
        let cipherData = RNCryptor.encrypt(data: randomData, withPassword: password)
        return cipherData.base64EncodedString()
    }
}

//MARK: - Constants

private struct UserModelConstants {
    static let lengthOfEncryptionKey = 32
}
