//
//  AboutViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 07.12.2021.
//

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        actions.createAction(user: users.currentUser, date: Date(), userAction: "Visit about page")
    }
    var users: Users!
    let actions = Actions()

    @IBAction func toAccountView(_ sender: UIButton) {
        performSegue(withIdentifier: "account", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let AccountVC = segue.destination as? AccountViewController{
            AccountVC.users = self.users
        }
    }

    
}
