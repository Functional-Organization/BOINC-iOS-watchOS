//
//  SavedProjectsTableViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 8/1/17.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit
import os.log
import WatchConnectivity
import StoreKit
import SafariServices

class SavedProjectsTableViewController: UITableViewController, WCSessionDelegate {
    // MARK: Properties
    var addedProjects = [Project]()
    
    let session = WCSession.default

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load any saved projects.
        if let savedProjects = loadProjects() {
            addedProjects += savedProjects
            // If the user has added projects, occasionally ask if they'd like to rate the app.
//            if #available(iOS 10.3, *) {
//                SKStoreReviewController.requestReview()
//            } else {
//                // Fallback on earlier versions
//            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedProjects.count
    }
    
    // MARK: - Actions
    @IBAction func unwingToAddedProjectsList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ProjectViewController, let project = sourceViewController.project {
            // Add a new project.
            let newIndexPath = IndexPath(row: addedProjects.count, section: 0)
            addedProjects.append(project)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    
    @IBAction func presentNews(_ sender: UIBarButtonItem) {
        let newsURL = URL(string:"https://boinc.berkeley.edu/old_news.php")
        let newsViewController = SFSafariViewController(url: newsURL!)
        newsViewController.modalPresentationStyle = .popover
        present(newsViewController, animated: true)
    }
    
    @IBAction func presentMessageBoards(_ sender: UIBarButtonItem) {
        let messageBoardsURL = URL(string: "https://boinc.berkeley.edu/forum_index.php")
        let messageBoardsViewController = SFSafariViewController(url: messageBoardsURL!)
        messageBoardsViewController.modalPresentationStyle = .popover
        present(messageBoardsViewController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "addedProjectsTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SavedProjectsTableViewCell else {
            fatalError("The dequeued cell is not an instance of \(self).")
        }

        // Fetches the appropriate project for the data source layout.
        let project = addedProjects[indexPath.row]
        
        cell.nameLabel.text = project.name
        if project.authenticator == nil {
            project.fetchAuthenticator(project.homePage, project.username, project.password!) { (authenticator) in
                project.fetch(.showUserInfo, authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit) in
                    DispatchQueue.main.sync {
                        let formattedAverageCredit = self.formatCredit(averageCredit)
                        cell.averageCreditLabel.text = "\(NSLocalizedString("Average credit:", tableName: "Main", comment: "")) " + formattedAverageCredit
                        
                        let formattedTotalCredit = self.formatCredit(totalCredit)
                        cell.totalCreditLabel.text = "\(NSLocalizedString("Total credit:", tableName: "Main", comment: "")) " + formattedTotalCredit
                        
                        project.authenticator = authenticator
                        self.saveProjectsAndSendToWatch()
                    }
                }
            }
        } else if project.authenticator != nil && addedProjects.count > 0 {
            project.fetch(.showUserInfo, project.authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    let formattedAverageCredit = self.formatCredit(averageCredit)
                    cell.averageCreditLabel.text = "\(NSLocalizedString("Average credit:", tableName: "Main", comment: "")) " + formattedAverageCredit
                    
                    let formattedTotalCredit = self.formatCredit(totalCredit)
                    cell.totalCreditLabel.text = "\(NSLocalizedString("Total credit:", tableName: "Main", comment: "")) " + formattedTotalCredit
                    
                    self.saveProjectsAndSendToWatch()
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            addedProjects.remove(at: indexPath.row)
            saveProjectsAndSendToWatch()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    private func saveProjectsAndSendToWatch() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(addedProjects, toFile: Project.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Projects successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save projects...", log: OSLog.default, type: .error)
        }
        do {
            var contextToBeSent = [[String]]()
            if addedProjects.count > 0 {
                for index in 0...addedProjects.count - 1 {
                    contextToBeSent.append([addedProjects[index].name, addedProjects[index].username, addedProjects[index].authenticator!, addedProjects[index].averageCredit, addedProjects[index].totalCredit, addedProjects[index].homePage])
                }
                try session.updateApplicationContext(["Added projects" : contextToBeSent])
            }
            else if addedProjects.isEmpty {
                try session.updateApplicationContext(["Empty list of projects" : true])
            }
        } catch {
            print("Unable to update application context.")
        }
    }
    
    private func loadProjects() -> [Project]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Project.ArchiveURL.path) as? [Project]
    }
}
