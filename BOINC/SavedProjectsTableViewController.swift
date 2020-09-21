//
//  SavedProjectsTableViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 8/1/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit
import os.log
import WatchConnectivity
import StoreKit
import SafariServices

class SavedProjectsTableViewController: UITableViewController, WCSessionDelegate {
    // MARK: Properties
    var addedProjects = [ProjectDetail]()
    
    let session = WCSession.default

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRefreshControl()
        
        if let savedProjects = loadProjects() {
            addedProjects += savedProjects
        }
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
        if let sourceViewController = sender.source as? LoginViewController, let project = sourceViewController.selectedProject {
            // Add a new project.
            let newIndexPath = IndexPath(row: addedProjects.count, section: 0)
            addedProjects.append(project)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        SKStoreReviewController.requestReview()
    }
    
    @IBAction func presentNews(_ sender: UIBarButtonItem) {
        let newsURL = URL(string:"https://boinc.berkeley.edu/old_news.php")
        let newsViewController = SFSafariViewController(url: newsURL!)
        newsViewController.modalPresentationStyle = .pageSheet
        present(newsViewController, animated: true)
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
            project.fetchAuthenticator(project.homePage, project.username, project.password!) { (authenticator, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default)
                        alert.addAction(defaultAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
                project.fetch(.showUserInfo, authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit, error) in
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
            project.fetch(.showUserInfo, project.authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default)
                        alert.addAction(defaultAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        let formattedAverageCredit = self.formatCredit(averageCredit)
                        cell.averageCreditLabel.text = formattedAverageCredit
                        
                        let formattedTotalCredit = self.formatCredit(totalCredit)
                        cell.totalCreditLabel.text = formattedTotalCredit
                        
                        self.saveProjectsAndSendToWatch()
                    }
                }
            }
        }
        
        if addedProjects[indexPath.row] == addedProjects.last {
            refreshControl?.endRefreshing()
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
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(addedProjects, toFile: ProjectDetail.ArchiveURL.path)
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
    
    private func loadProjects() -> [ProjectDetail]? {
        NSKeyedUnarchiver.setClass(ProjectDetail.self, forClassName: "BOINC.Project")
        return NSKeyedUnarchiver.unarchiveObject(withFile: ProjectDetail.ArchiveURL.path) as? [ProjectDetail]
    }
    
    // MARK: - Refresh
    
    func configureRefreshControl () {
        tableView.refreshControl?.isEnabled = true
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        tableView.reloadData()
        if addedProjects.isEmpty { tableView.refreshControl?.endRefreshing() }
    }
}
