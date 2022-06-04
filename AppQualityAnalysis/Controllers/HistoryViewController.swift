//
//  HistoryViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 07.12.2021.
//

import UIKit

//VC that controls view with user history
class HistoryViewController: UIViewController {

    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        userModel.createAction(date: Date(), userAction: "Visited history page")
    }
    
    //MARK: - Properties
    
    private typealias constants = HistoryVC_Constants
    
    var userModel: UserModel!
    
    //we decrease and increase this number to move through user history
    private var pagesIndex = 0
    
    @IBOutlet weak var userHistory: UIStackView!
    
    //MARK: - Buttons functions
    
    @IBAction func previousPage(_ sender: UIButton) {
        if pagesIndex + constants.valuesPerPage < userModel.currentUser!.actions.count{
            pagesIndex += constants.valuesPerPage
        }
        else{
            pagesIndex = 0
            if userModel.currentUser!.actions.count > constants.valuesPerPage {
                pagesIndex = userModel.currentUser!.actions.count - constants.valuesPerPage
            }
        }
        userHistory.removeFullyAllArrangedSubviews()
        fillList()
    }
    
    @IBAction func nextPage(_ sender: UIButton) {
        pagesIndex -= constants.valuesPerPage
        if pagesIndex < 0 {
            pagesIndex = 0
        }
        userHistory.removeFullyAllArrangedSubviews()
        fillList()
    }
    
    @IBAction func toAccountView(_ sender: UIButton) {
        performSegue(withIdentifier: "account", sender: self)
    }
    
    //MARK: - Local functions
    
    //makes StackView with user history
    private func fillList(){
        var currentIndex = 0
        let index = userModel.currentUser!.actions.count - constants.valuesPerPage - pagesIndex
        if index > 0 {
            currentIndex = index
        }
        for actionIndex in currentIndex...userModel.currentUser!.actions.count - pagesIndex - 1{
            let actionLabel = UILabel()
            actionLabel.numberOfLines = 0
            actionLabel.text = "\(userModel.currentUser!.nickname) \(constants.dateFormatter.string(from: userModel.currentUser!.actions[actionIndex].date)) \(userModel.currentUser!.actions[actionIndex].action)"
            actionLabel.font = constants.font
            userHistory.addArrangedSubview(actionLabel)
        }
        userHistory.sizeToFit()
        userHistory.layoutIfNeeded()
    }
    
    //MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let AccountVC = segue.destination as? AccountViewController{
            AccountVC.userModel = self.userModel
        }
    }
    
}

//MARK: - Constants

private struct HistoryVC_Constants {
    static let valuesPerPage = 5
    static let fontSize: CGFloat = 20
    static let dateFormat = "yyyy/MM/dd HH:mm:ss"
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }
    static let font = UIFont.preferredFont(forTextStyle: .title3)
}
