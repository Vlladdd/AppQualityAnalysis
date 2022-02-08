//
//  Users.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 04.12.2021.
//

import Foundation
import RealmSwift
import RNCryptor

class User: Object {
    @Persisted var nickname: String
    @Persisted var password: String
    @Persisted var passwordKey: String
    @Persisted var name: String!
    @Persisted var date: Date!
}

class Users {
    let realm = try! Realm()
    lazy var users = realm.objects(User.self)
    var currentUser: User!
    
    func createUser(nickname: String, password: String){
        try! realm.write {
            let user = User()
            user.nickname = nickname
            user.passwordKey = try! generateEncryptionKey(withPassword: password)
            user.password = try! encryptMessage(message: password, encryptionKey: user.passwordKey)
            currentUser = user
            realm.add(user)
        }
    }
    
    func findUser(nickname: String) -> Bool{
        let findUser = users.where {
            $0.nickname == nickname
        }
        if findUser.isEmpty == false {
            currentUser = findUser[0]
            return true
        }
        else {
            return false
        }
    }
    
    func checkPassword(password: String) -> Bool{
        if try! decryptMessage(encryptedMessage: currentUser.password, encryptionKey: currentUser.passwordKey) == password   {
            return true
        }
        else {
            return false
        }
    }
    
    func updateUser(nickname: String, password: String, name: String, date: Date){
        let findUser = users.where {
            $0.nickname == currentUser.nickname
        }
        try! realm.write {
            findUser[0].nickname = nickname
            findUser[0].passwordKey = try! generateEncryptionKey(withPassword: password)
            findUser[0].password = try! encryptMessage(message: password, encryptionKey: findUser[0].passwordKey)
            findUser[0].name = name
            findUser[0].date = date
        }
    }
    
    func encryptMessage(message: String, encryptionKey: String) throws -> String {
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
    
    func generateEncryptionKey(withPassword password:String) throws -> String {
        let randomData = RNCryptor.randomData(ofLength: 32)
        let cipherData = RNCryptor.encrypt(data: randomData, withPassword: password)
        return cipherData.base64EncodedString()
    }
}
