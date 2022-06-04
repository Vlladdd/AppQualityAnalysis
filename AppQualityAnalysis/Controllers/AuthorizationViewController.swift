//
//  AuthorizationViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 02.11.2021.
//

import UIKit
import RealmSwift

//VC that controls view with authorization to the app
class AuthorizationViewController: UIViewController {
    
    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        //some random data to test the app
//        let a = Reviews()
//        let b = Metrics()
//        let start = DispatchTime.now()
//        a.getReviewsFromAppStore(numPages: 10, appId: "284882215")
//        a.getReviewsFromAppStore(numPages: 10, appId: "324684580")
//        a.getReviewsFromAppStore(numPages: 8, appId: "880047117")
//        a.getReviewsFromAppStore(numPages: 2, appId: "603527166")
//        a.getReviewsFromAppStore(numPages: 10, appId: "564177498")
//        a.sortReviewsByCategories()
//        b.reviewsByCategories = a.reviewsByCategories
//        b.getMetrics()
//        let end = DispatchTime.now()
//        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
//        let timeInterval = Double(nanoTime) / 1_000_000_000
//        print(timeInterval)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        spinner.center = CGPoint(x: view.frame.midY, y: view.frame.midX)
    }
    
    //MARK: - Properties
    
    private typealias constants = AuthorizationVC_Constants
    
    private let userModel = UserModel()
    
    private lazy var spinner = makeSpinner()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var proceed: UIButton!
    
    //MARK: - Buttons Functions
    
    @IBAction func proceed(_ sender: UIButton) {
        proceed.isEnabled = false
        let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        view.addSubview(spinner)
        let username = username.text!
        let password = password.text!
        if username.count > constants.minCharactersInField && password.count > constants.minCharactersInField && username.count < constants.maxCharactersInField && password.count < constants.maxCharactersInField {
            DispatchQueue.global().async {[weak self] in
                if let self = self {
                    let findUser = self.userModel.findUser(nickname: username, password: password)
                    DispatchQueue.main.async {
                        switch findUser {
                        case .wrongPassword:
                            alertController.message = "Wrong password!"
                            self.present(alertController, animated: true, completion: nil)
                            self.spinner.removeFromSuperview()
                            self.proceed.isEnabled = true
                        case .success:
                            self.spinner.removeFromSuperview()
                            self.proceed.isEnabled = true
                            self.performSegue(withIdentifier: "main", sender: self)
                        }
                    }
                }
            }
        }
        else {
            alertController.message = "Username or password too short or too long! Must be > \(constants.minCharactersInField) and < \(constants.maxCharactersInField)"
            present(alertController, animated: true, completion: nil)
            spinner.removeFromSuperview()
            proceed.isEnabled = true
        }
    }
    
    //MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? TabBarViewController{
            let AnalyzeVC = tabBarController.viewControllers![0] as? AnalyzeViewController
            AnalyzeVC!.userModel = self.userModel
            let AccountVC = tabBarController.viewControllers![2] as? AccountViewController
            AccountVC!.userModel = self.userModel
            let CompareVC = tabBarController.viewControllers![1] as? CompareViewController
            CompareVC!.userModel = self.userModel
        }
        
    }
    
}

//MARK: - Constants

private struct AuthorizationVC_Constants {
    static let minCharactersInField = 6
    static let maxCharactersInField = 13
}

