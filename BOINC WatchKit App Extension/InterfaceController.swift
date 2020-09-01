//
//  InterfaceController.swift
//  BOINC WatchKit App Extension
//
//  Created by Austin Conlon on 8/26/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import os.log

class InterfaceController: WKInterfaceController, WCSessionDelegate, XMLParserDelegate {
    @IBOutlet var addedProjectsTable: WKInterfaceTable!
    var addedProjects = [[String]]()
    var addedProjectsToSaveAndLoad = [ProjectDetail]()
    enum Queries {
        case showUserInfo
    }
    var dataFromLookingUpAccount: Data?
    var authenticator: String?
    var elementName: String?
    var totalCredit: String?
    var averageCredit: String?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        // Load any saved projects.
        if let savedProjects = loadProjects() {
            addedProjectsToSaveAndLoad += savedProjects
            fetchDataForEachProject()
        }
    }
    
    func configureTable() {
        self.addedProjectsTable.setNumberOfRows(addedProjects.count, withRowType: "mainRowType")
        if addedProjects.isEmpty == false {
            for project in 0...addedProjects.count - 1 {
                let theRow = self.addedProjectsTable.rowController(at: project) as! AddedProjectsRowController
                theRow.nameLabel.setText(addedProjects[project][0])
                theRow.averageCreditLabel.setText(formatCredit(addedProjects[project][3]))
                theRow.totalCreditLabel.setText(formatCredit(addedProjects[project][4]))
            }
        }
    }
    
    func configureTableWithFetchedData() {
        self.addedProjectsTable.setNumberOfRows(addedProjectsToSaveAndLoad.count, withRowType: "mainRowType")
        for project in 0...addedProjectsToSaveAndLoad.count - 1 {
            let theRow = self.addedProjectsTable.rowController(at: project) as! AddedProjectsRowController
            theRow.nameLabel.setText(addedProjectsToSaveAndLoad[project].name)
            theRow.averageCreditLabel.setText(formatCredit(addedProjectsToSaveAndLoad[project].averageCredit))
            theRow.totalCreditLabel.setText(formatCredit(addedProjectsToSaveAndLoad[project].totalCredit))
        }
    }
    
    func formatCredit(_ creditToBeFormatted: String) -> String {
        let credit = Float(creditToBeFormatted)
        let creditTruncated = String(format: "%.0f", credit!)
        let creditTruncatedAndFormatted = Int(creditTruncated)
        let creditNumberFormatter = NumberFormatter()
        creditNumberFormatter.numberStyle = NumberFormatter.Style.decimal
        return creditNumberFormatter.string(from: NSNumber(value: creditTruncatedAndFormatted!))!
    }
    
    func fetchDataForEachProject() {
        for project in 0...addedProjectsToSaveAndLoad.count - 1 {
            let authenticator = addedProjectsToSaveAndLoad[project].authenticator!
            let homePage = addedProjectsToSaveAndLoad[project].homePage
            let username = addedProjectsToSaveAndLoad[project].username
            addedProjectsToSaveAndLoad[project].fetch(.showUserInfo, authenticator, homePage, username: username) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    self.configureTableWithFetchedData()
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let addedProjects = applicationContext["Added projects"] {
            self.addedProjects = addedProjects as! [[String]]
            configureTable()
            saveProjects()
        }
        if let _ = applicationContext["Empty list of projects"] {
            self.addedProjectsTable.setNumberOfRows(0, withRowType: "mainRowType")
            addedProjects.removeAll()
            saveProjects()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    private func saveProjects() {
        addedProjectsToSaveAndLoad.removeAll()
        if addedProjects.count > 0 {
            for project in 0...addedProjects.count - 1 {
                let name = addedProjects[project][0]
                let email = addedProjects[project][1]
                let authenticator = addedProjects[project][2]
                let averageCredit = addedProjects[project][3]
                let totalCredit = addedProjects[project][4]
                let homePage = addedProjects[project][5]
                addedProjectsToSaveAndLoad.append(ProjectDetail(name: name, email, authenticator, averageCredit, totalCredit, homePage))
            }
        }
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(addedProjectsToSaveAndLoad, toFile: ProjectDetail.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Projects successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save projects...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadProjects() -> [ProjectDetail]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: ProjectDetail.ArchiveURL.path) as? [ProjectDetail]
    }
    
    // MARK: URLSession Methods
    func fetch(_ query: Queries, _ authenticator: String, projectHomePage: String, _ email: String, completion: @escaping () -> Void) {
        let URL = generateURL(query, projectHomePage, authenticator, email)
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: URL) { (data, response, error) in
            self.parseReturnedXML(data!)
            completion()
        }
        task.resume()
    }
    
    func generateURLForFetchingAuthenticator(_ projectHomePage: String, _ email: String, _ hash: String) -> URL {
        let urlToFetchAuthenticatorFrom = URL(string: projectHomePage + "/lookup_account.php?email_addr=" + email + "&passwd_hash=" + hash)!
        return urlToFetchAuthenticatorFrom
    }
    
    func generateURL(_ query: Queries, _ projectHomePage: String, _ authenticator: String, _ email: String) -> URL {
        let urlToQuery = URL(string: projectHomePage + "/show_user.php?auth=" + authenticator + "&format=xml")!
        return urlToQuery
    }
    
    // MARK: XMLParser Methods
    func parseReturnedXML(_ data: Data?) {
        let parser = XMLParser(data: data!)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        self.elementName = elementName
        if elementName == "authenticator" {
            authenticator = String()
        }
        else if elementName == "total_credit" {
            totalCredit = String()
        }
        else if elementName == "expavg_credit" {
            averageCredit = String()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if !data.isEmpty {
            if elementName == "authenticator" {
                authenticator = data
            }
            else if elementName == "total_credit" {
                totalCredit = data
            }
            else if elementName == "expavg_credit" {
                averageCredit = data
                parser.abortParsing()
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { }
}
