//
//  AddedProjectsTableViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 8/1/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import UIKit
import os.log

class AddedProjectsTableViewController: UITableViewController {
    // MARK: Properties
    
    var addedProjects = [Project]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Load any saved projects.
        if let savedProjects = loadProjects() {
            addedProjects += savedProjects
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return addedProjects.count
    }
    
    // MARK: Actions
    
    @IBAction func unwingToAddedProjectsList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ProjectViewController, let project = sourceViewController.project {
            // Add a new project.
            let newIndexPath = IndexPath(row: addedProjects.count, section: 0)
            addedProjects.append(project)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            saveProjects()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "addedProjectsTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AddedProjectsTableViewCell else {
            fatalError("The dequeued cell is not an instance of AddedProjectsTableViewCell.")
        }

        // Fetches the appropriate project for the data source layout.
        let project = addedProjects[indexPath.row]
        
        cell.nameLabel.text = project.name
        if project.authenticator == nil {
            project.fetchAuthenticator(project.homePage, project.email, project.password) { (authenticator) in
                project.fetch(.showUserInfo, authenticator!, projectHomePage: project.homePage, project.email) { (averageCredit, totalCredit) in
                    DispatchQueue.main.sync {
                        let formattedAverageCredit = self.formatCredit(averageCredit)
                        cell.averageCreditLabel.text = "Average credit: " + formattedAverageCredit
                        
                        let formattedTotalCredit = self.formatCredit(totalCredit)
                        cell.totalCreditLabel.text = "Total credit: " + formattedTotalCredit
                        
                        project.authenticator = authenticator
                        self.saveProjects()
                    }
                }
            }
        }
        else if project.authenticator != nil && addedProjects.count > 0 {
            project.fetch(.showUserInfo, project.authenticator!, projectHomePage: project.homePage, project.email) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    let formattedAverageCredit = self.formatCredit(averageCredit)
                    cell.averageCreditLabel.text = "Average credit: " + formattedAverageCredit
                    
                    let formattedTotalCredit = self.formatCredit(totalCredit)
                    cell.totalCreditLabel.text = "Total credit: " + formattedTotalCredit
                    
                    self.saveProjects()
                }
            }
        }
        return cell
    }
    
    func formatCredit(_ creditToBeFormatted: String) -> String {
        let credit = Float(creditToBeFormatted)
        let creditTruncated = String(format: "%.0f", credit!)
        let creditTruncatedAndFormatted = Int(creditTruncated)
        let creditNumberFormatter = NumberFormatter()
        creditNumberFormatter.numberStyle = NumberFormatter.Style.decimal
        return creditNumberFormatter.string(from: NSNumber(value: creditTruncatedAndFormatted!))!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            addedProjects.remove(at: indexPath.row)
            saveProjects()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func saveProjects() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(addedProjects, toFile: Project.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Projects successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save projects...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadProjects() -> [Project]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Project.ArchiveURL.path) as? [Project]
    }
}
