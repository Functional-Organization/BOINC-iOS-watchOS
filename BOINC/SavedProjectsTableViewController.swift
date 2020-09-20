//
//  SavedProjectsTableViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 8/1/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit
import os.log
import StoreKit
import SafariServices
import SwiftUI

class SavedProjectsTableViewController: UITableViewController {
    // MARK: Properties
    var addedProjects = [ProjectDetail]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRefreshControl()
        
        if let savedProjects = loadProjects() {
            addedProjects += savedProjects
            // If the user has added projects, occasionally ask if they'd like to rate the app.
            if #available(iOS 10.3, *) {
//                SKStoreReviewController.requestReview()
            } else {
                // Fallback on earlier versions
            }
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
            project.fetchAuthenticator(project.homePage, project.username, project.password!) { (authenticator) in
                project.fetch(.showUserInfo, authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit) in
                    DispatchQueue.main.sync {
                        let formattedAverageCredit = self.formatCredit(averageCredit)
                        cell.averageCreditLabel.text = "\(NSLocalizedString("Average credit:", tableName: "Main", comment: "")) " + formattedAverageCredit
                        
                        let formattedTotalCredit = self.formatCredit(totalCredit)
                        cell.totalCreditLabel.text = "\(NSLocalizedString("Total credit:", tableName: "Main", comment: "")) " + formattedTotalCredit
                        
                        project.authenticator = authenticator
                    }
                }
            }
        } else if project.authenticator != nil && addedProjects.count > 0 {
            project.fetch(.showUserInfo, project.authenticator!, project.homePage, username: project.username) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    let formattedAverageCredit = self.formatCredit(averageCredit)
                    cell.averageCreditLabel.text = formattedAverageCredit
                    
                    let formattedTotalCredit = self.formatCredit(totalCredit)
                    cell.totalCreditLabel.text = formattedTotalCredit
                }
            }
        }
        
        if addedProjects[indexPath.row] == addedProjects.last {
            refreshControl?.endRefreshing()
        }
        
        return cell
    }
    
    func formatCredit(_ creditToBeFormatted: Float) -> String {
        let creditNumberFormatter = NumberFormatter()
        creditNumberFormatter.numberStyle = NumberFormatter.Style.decimal
        return creditNumberFormatter.string(from: NSNumber(value: creditToBeFormatted))!
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source.
            addedProjects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(UIHostingController(rootView: DetailView(project: addedProjects[indexPath.row])), animated: true)
    }
    
    private func loadProjects() -> [ProjectDetail]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: ProjectDetail.ArchiveURL.path) as? [ProjectDetail]
    }
    
    // MARK: - Refresh
    
    func configureRefreshControl () {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        tableView.reloadData()
    }
}
