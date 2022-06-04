//
//  AboutViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 07.12.2021.
//

import UIKit

//VC that controls view with info about app
class AboutViewController: UIViewController {
    
    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        userModel.createAction(date: Date(), userAction: "Visited about page")
    }
    
    //MARK: - Properties
    
    var userModel: UserModel!
    
    //MARK: - Buttons Functions

    @IBAction func toAccountView(_ sender: UIButton) {
        performSegue(withIdentifier: "account", sender: self)
    }
    
    //MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let AccountVC = segue.destination as? AccountViewController{
            AccountVC.userModel = self.userModel
        }
    }

}
