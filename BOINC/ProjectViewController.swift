//
//  ProjectViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 7/27/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import Foundation
import UIKit
import os

class ProjectViewController: UIViewController, UITextFieldDelegate {

    

    // MARK: Properties
    var project: Project?
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var passwordAndUsername = ""
    var selectedRow: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        project = Project(name: self.title!)
        project!.homePage = projects[selectedRow!].1
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // Enable the Save button only if the text field has valid Project credentials.
        saveButton.isEnabled = false
        
        if project?.name == "World Community Grid" {
            usernameTextField.placeholder = "Username"
            if #available(iOS 11.0, *) {
                usernameTextField.textContentType = .username
            } else {
                // Fallback on earlier versions
            }
            usernameTextField.keyboardType = .default
            passwordTextField.isHidden = true
        } else {
            usernameTextField.textContentType = .emailAddress
        }
        
        usernameTextField.becomeFirstResponder()
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let usernameText = usernameTextField.text ?? ""
        let passwordText = passwordTextField.text ?? ""
        project?.username = usernameText
        project?.password = passwordText
        
        if project?.name == "World Community Grid" {
            project!.fetch(.showUserInfo, username: usernameText) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    // TODO: check if username is valid.
                    self.saveButton.isEnabled = true
                }
            }
        } else if (!usernameText.isEmpty && !passwordText.isEmpty) {
            project!.fetchAuthenticator((project!.homePage), usernameText, passwordText) { (authenticator) in
                DispatchQueue.main.sync {
                    if authenticator != nil {
                        self.saveButton.isEnabled = true
                    }
                    else {
                        let alert = UIAlertController(title: "Incorrect login", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default)
                        alert.addAction(defaultAction)
                        self.present(alert, animated: true, completion: nil)
                        self.saveButton.isEnabled = false
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the running projects view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
}
