//
//  ViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 02.11.2021.
//

import UIKit
import RealmSwift
import RNCryptor

class AuthorizationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
//        let a = Reviews()
//        let b = Metrics()
//        let start = DispatchTime.now()
//        a.getReviewsFromAppStore(numPages: 10, appId: "284882215")
////        a.getReviewsFromAppStore(numPages: 10, appId: "324684580")
////        a.getReviewsFromAppStore(numPages: 8, appId: "880047117")
////        a.getReviewsFromAppStore(numPages: 2, appId: "603527166")
////        a.getReviewsFromAppStore(numPages: 10, appId: "564177498")
//        a.sortReviewsByCategories()
//        b.reviewsByCategories = a.reviewsByCategories
//        b.getMetrics()
//        let end = DispatchTime.now()
//        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
//        let timeInterval = Double(nanoTime) / 1_000_000_000
//        print(timeInterval)
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    let users = Users()
    let actions = Actions()
    
    
    @IBAction func proceed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Error", message:
                                                    "Hello, world!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        if username.text!.count > 6 && password.text!.count > 6 && username.text!.count < 13 && password.text!.count < 13 {
            if users.findUser(nickname: username.text!){
                if users.checkPassword(password: password.text!){
                    actions.createAction(user: users.currentUser, date: Date(), userAction: "Authorization complete")
                    performSegue(withIdentifier: "main", sender: self)
                }
                else {
                    alertController.message = "Wrong password!"
                    present(alertController, animated: true, completion: nil)
                }
            }
            else {
                users.createUser(nickname: username.text!, password: password.text!)
                actions.createAction(user: users.currentUser, date: Date(), userAction: "Account created")
                performSegue(withIdentifier: "main", sender: self)
            }
        }
        else {
            alertController.message = "Username or password too short or too long! Must be > 6 and < 13"
            present(alertController, animated: true, completion: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? TabBarViewController{
            let AnalyzeVC = tabBarController.viewControllers![0] as? AnalyzeViewController
            AnalyzeVC!.users = self.users
            let AccountVC = tabBarController.viewControllers![2] as? AccountViewController
            AccountVC!.users = self.users
            let CompareVC = tabBarController.viewControllers![1] as? CompareViewController
            CompareVC!.users = self.users
        }
        
    }
    
}

