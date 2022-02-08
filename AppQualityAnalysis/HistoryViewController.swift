//
//  HistoryViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 07.12.2021.
//

import UIKit

class HistoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        actions.findActions(user: users.currentUser)
        fillList()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        actions.createAction(user: users.currentUser, date: Date(), userAction: "Visit history page")
    }
    var users: Users!
    let actions = Actions()
    var pagesIndex = 0
    let formatter = DateFormatter()
    @IBOutlet weak var userHistory: UIStackView!
    
    @IBAction func previousPage(_ sender: UIButton) {
        if pagesIndex + 5 < actions.currentUserActions.count{
            pagesIndex += 5
        }
        else{
            pagesIndex = 0
            if actions.currentUserActions.count > 5 {
                pagesIndex = actions.currentUserActions.count - 5
            }
        }
        userHistory.removeFullyAllArrangedSubviews()
        fillList()
    }
    
    @IBAction func nextPage(_ sender: UIButton) {
        pagesIndex -= 5
        if pagesIndex < 0 {
            pagesIndex = 0
        }
        userHistory.removeFullyAllArrangedSubviews()
        fillList()
    }
    
    @IBAction func toAccountView(_ sender: UIButton) {
        performSegue(withIdentifier: "account", sender: self)
    }
    
    func fillList(){
        var index = 0
        let result = actions.currentUserActions.count-5-pagesIndex
        if result > 0 {
            index = result
        }
        for x in index...actions.currentUserActions.count-pagesIndex-1{
            let label = UILabel()
            label.numberOfLines = 0
            label.textColor = UIColor.black
            label.text = "\(actions.currentUserActions[x].user.nickname) \(formatter.string(from: actions.currentUserActions[x].date)) \(actions.currentUserActions[x].action)"
            label.font = UIFont(name: "Times New Roman", size: 20)
            userHistory.addArrangedSubview(label)
        }
        userHistory.sizeToFit()
        userHistory.layoutIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let AccountVC = segue.destination as? AccountViewController{
            AccountVC.users = self.users
        }
    }
    
}

extension UIStackView {

    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }

}
