//
//  AccountViewController.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 05.12.2021.
//

import UIKit

class AccountViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        if users.currentUser.date != nil {
            birthDate.text = dateFormatter.string(from: users.currentUser.date)
        }
        username.text = users.currentUser.nickname
        password.text = try! users.decryptMessage(encryptedMessage: users.currentUser.password, encryptionKey: users.currentUser.passwordKey)
        name.text = users.currentUser.name
        showDatePicker()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        actions.createAction(user: users.currentUser, date: Date(), userAction: "Visit account page")
    }
    var users: Users!
    let actions = Actions()
    let datePicker = UIDatePicker()
    let dateFormatter = DateFormatter()
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var birthDate: UITextField!
    
    @IBAction func update(_ sender: UIButton) {
        dateFormatter.dateFormat = "dd/MM/yyyy" //Your date format
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00") //Current time zone
        //according to date format your date string
        var date: Date!
        if !birthDate.text!.isEmpty {
            date = dateFormatter.date(from: birthDate.text!)
        }
        let alertController = UIAlertController(title: "Error", message:
                                                    "Hello, world!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        if username.text!.count > 6 && password.text!.count > 6 && name.text!.count > 6 && username.text!.count < 13 && password.text!.count < 13 && name.text!.count < 13{
            if users.findUser(nickname: username.text!) && username.text != users.currentUser.nickname{
                alertController.message = "This nickname already exist!"
                present(alertController, animated: true, completion: nil)
            }
            else {
                users.updateUser(nickname: username.text!, password: password.text!, name: name.text!, date: date)
                if users.currentUser.date != nil {
                    birthDate.text = dateFormatter.string(from: users.currentUser.date)
                }
                username.text = users.currentUser.nickname
                password.text = try! users.decryptMessage(encryptedMessage: users.currentUser.password, encryptionKey: users.currentUser.passwordKey)
                name.text = users.currentUser.name
                actions.createAction(user: users.currentUser, date: Date(), userAction: "Update account information")
            }
        }
        else {
            alertController.message = "Username,name and password too short or too long! Must be > 6 and < 13"
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func toHistoryView(_ sender: UIButton) {
        performSegue(withIdentifier: "history", sender: self)
    }
    
    @IBAction func toAboutView(_ sender: UIButton) {
        performSegue(withIdentifier: "about", sender: self)
    }
    
    func showDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .date
        
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donedatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        birthDate.inputAccessoryView = toolbar
        birthDate.inputView = datePicker
        
    }
    
    @IBAction func backFromModal(_ segue: UIStoryboardSegue) {
    }
    
    @objc func donedatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        birthDate.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker(){
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let HistoryVC = segue.destination as? HistoryViewController{
            HistoryVC.users = self.users
        }
        if let AboutVC = segue.destination as? AboutViewController{
            AboutVC.users = self.users
        }
    }
}
