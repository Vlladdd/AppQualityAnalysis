//
//  AccountViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 05.12.2021.
//

import UIKit

//VC that controls view with info about User
class AccountViewController: UIViewController {
    
    //MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        if userModel.currentUser!.date != nil {
            birthDate.text = constants.dateFormatter.string(from: userModel.currentUser!.date!)
        }
        nickname.text = userModel.currentUser!.nickname
        password.text = try? userModel.decryptMessage(encryptedMessage: userModel.currentUser!.password, encryptionKey: userModel.currentUser!.passwordKey)
        name.text = userModel.currentUser!.name
        addDatePicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
        userModel.createAction(date: Date(), userAction: "Visited account page")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        spinner.center = CGPoint(x: view.frame.midY, y: view.frame.midX)
    }
    
    //MARK: - Properties
    
    private typealias constants = AccountVC_Constants
    
    var userModel: UserModel!
    
    private let datePicker = UIDatePicker()
    private let alertController = UIAlertController(title: "Error", message: "Hello, world!", preferredStyle: .alert)
    
    private lazy var spinner = makeSpinner()
    
    @IBOutlet weak var nickname: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var birthDate: UITextField!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var topButtonsStack: UIStackView!
    
    //MARK: - Buttons Functions
    
    //deletes user
    @IBAction func deleteUser(_ sender: UIButton) {
        userModel.deleteUser()
        performSegue(withIdentifier: "authorization", sender: self)
    }
    
    //updates info about user
    @IBAction func update(_ sender: UIButton) {
        updateButton.isEnabled = false
        deleteButton.isEnabled = false
        view.addSubview(spinner)
        var date: Date?
        if !birthDate.text!.isEmpty {
            date = constants.dateFormatter.date(from: birthDate.text!)
        }
        let nickname = nickname.text!
        let password = password.text!
        let name = name.text!
        if nickname.count > constants.minCharactersInField && password.count > constants.minCharactersInField && name.count > constants.minCharactersInField && nickname.count < constants.maxCharactersInField && password.count < constants.maxCharactersInField && name.count < constants.maxCharactersInField{
            DispatchQueue.global().async {[weak self] in
                if let self = self {
                    let updateUser = self.userModel.updateUser(nickname: nickname, password: password, name: name, date: date)
                    DispatchQueue.main.sync {
                        switch updateUser {
                        case .wrongNickname:
                            self.showAlert(message: "This nickname already exist!")
                        case .success:
                            if self.userModel.currentUser!.date != nil {
                                self.birthDate.text = constants.dateFormatter.string(from: self.userModel.currentUser!.date!)
                            }
                            self.nickname.text = self.userModel.currentUser!.nickname
                            self.password.text = try? self.userModel.decryptMessage(encryptedMessage: self.userModel.currentUser!.password, encryptionKey: self.userModel.currentUser!.passwordKey)
                            self.name.text = self.userModel.currentUser!.name
                        case .failure:
                            self.showAlert(message: "Something went wrong!")
                        }
                        self.spinner.removeFromSuperview()
                        self.updateButton.isEnabled = true
                        self.deleteButton.isEnabled = true
                    }
                }
            }
        }
        else {
            showAlert(message: "Username,name and password too short or too long! Must be > \(constants.minCharactersInField) and < \(constants.maxCharactersInField)")
        }
    }
    
    @IBAction func toHistoryView(_ sender: UIButton) {
        performSegue(withIdentifier: "history", sender: self)
    }
    
    @IBAction func toAboutView(_ sender: UIButton) {
        performSegue(withIdentifier: "about", sender: self)
    }
    
    //MARK: - Local Functions
    
    private func showAlert(message: String) {
        alertController.message = message
        present(alertController, animated: true, completion: nil)
        updateButton.isEnabled = true
        deleteButton.isEnabled = true
        spinner.removeFromSuperview()
    }
    
    //adds date picker to the view
    private func addDatePicker(){
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneWithDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        birthDate.inputAccessoryView = toolbar
        birthDate.inputView = datePicker
    }
    
    @objc private func doneWithDatePicker(){
        birthDate.text = constants.dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc private func cancelDatePicker(){
        self.view.endEditing(true)
    }
    
    //MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let HistoryVC = segue.destination as? HistoryViewController{
            HistoryVC.userModel = self.userModel
        }
        if let AboutVC = segue.destination as? AboutViewController{
            AboutVC.userModel = self.userModel
        }
    }
    
    //comebacks from about and history view to this view
    @IBAction func backFromModal(_ segue: UIStoryboardSegue) {
    }
    
}

//MARK: - Constants

private struct AccountVC_Constants {
    static let dateFormat = "dd/MM/yyyy"
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }
    static let minCharactersInField = 6
    static let maxCharactersInField = 13
}
