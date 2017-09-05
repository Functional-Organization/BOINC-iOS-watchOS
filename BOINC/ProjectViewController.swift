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
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var passwordAndUsername = ""
    var selectedRow: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        project = Project(name: self.title!)
        project!.homePage = projectsToSelectFrom[selectedRow!].1
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // Enable the Save button only if the text field has valid Project credentials.
        saveButton.isEnabled = false
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let emailText = emailTextField.text ?? ""
        let passwordText = passwordTextField.text ?? ""
        project?.email = emailText
        project?.password = passwordText
        
        if (!emailText.isEmpty && !passwordText.isEmpty) {
            project!.fetchAuthenticator((project!.homePage), emailText, passwordText) { (authenticator) in
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
