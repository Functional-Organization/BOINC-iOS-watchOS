//
//  LoginViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 7/27/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation
import UIKit
import os

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var selectedProject: ProjectDetail?
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    
    var passwordAndUsername = ""
    var selectedRow: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedProject = ProjectDetail(name: self.title!)
        selectedProject!.homePage = projects[selectedRow!].1
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // Enable the Save button only if the text field has valid project credentials.
        saveButton.isEnabled = false
        
        if selectedProject?.name == "World Community Grid" {
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
        selectedProject?.username = usernameText
        selectedProject?.password = passwordText
        
        if selectedProject?.name == "World Community Grid" {
            selectedProject!.fetch(.showUserInfo, username: usernameText) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    // TODO: check if username is valid.
                    self.saveButton.isEnabled = true
                }
            }
        } else if (!usernameText.isEmpty && !passwordText.isEmpty) {
            selectedProject!.fetchAuthenticator((selectedProject!.homePage), usernameText, passwordText) { (authenticator) in
                DispatchQueue.main.sync {
                    if !authenticator!.isEmpty {
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the running projects view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
}
