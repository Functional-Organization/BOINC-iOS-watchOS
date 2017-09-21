//
//  InterfaceController.swift
//  BOINC WatchKit App Extension
//
//  Created by Austin Conlon on 8/26/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import os.log

class InterfaceController: WKInterfaceController, WCSessionDelegate, XMLParserDelegate {
    @IBOutlet var addedProjectsTable: WKInterfaceTable!
    var addedProjects = [[String]]()
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
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        // Configure interface objects here.
        if let savedProjects = loadProjects() { // Load any saved projects.
            configureTableWithData()
            fetchDataForEachProject(savedProjects)
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func configureTableWithData() {
        self.addedProjectsTable.setNumberOfRows(addedProjects.count, withRowType: "mainRowType")
        if addedProjects.isEmpty == false {
            for project in 0...addedProjects.count - 1 {
                let theRow = self.addedProjectsTable.rowController(at: project) as! AddedProjectsRowController
                theRow.nameLabel.setText(addedProjects[project][0])
                let formattedAverageCredit = formatCredit(addedProjects[project][3])
                let formattedTotalCredit = formatCredit(addedProjects[project][4])
                theRow.averageCreditLabel.setText(formattedAverageCredit)
                theRow.totalCreditLabel.setText(formattedTotalCredit)
            }
        }
    }
    
    func configureTableWithDataObjects(_ projectsDataObjects: [Project]) {
        self.addedProjectsTable.setNumberOfRows(projectsDataObjects.count, withRowType: "mainRowType")
        if projectsDataObjects.count > 0 {
            for projectsDataObjectsIndex in 0...projectsDataObjects.count - 1 {
                let theRow = self.addedProjectsTable.rowController(at: projectsDataObjectsIndex) as! AddedProjectsRowController
                let name = projectsDataObjects[projectsDataObjectsIndex].name
                let averageCredit = projectsDataObjects[projectsDataObjectsIndex].averageCredit
                let totalCredit = projectsDataObjects[projectsDataObjectsIndex].totalCredit
                
                let formattedAverageCredit = self.formatCredit(averageCredit)
                let formattedTotalAverageCredit = self.formatCredit(totalCredit)
                
                theRow.nameLabel.setText(name)
                theRow.averageCreditLabel.setText(formattedAverageCredit)
                theRow.totalCreditLabel.setText(formattedTotalAverageCredit)
            }
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
    
    func populateTableWithDataFromPhone(_ applicationContext: [String : [String]]) -> [[String]] {
        var projectData = [String]()
        var projectsNamesAndData = [[String]]()
        
        for (projectName, _) in applicationContext {
            for index in 0...5 { // Populate an array of the project's properties.
                let projectDatum = [applicationContext[projectName]![index]]
                projectData += projectDatum
            }
            projectsNamesAndData.append(projectData)
            projectData.removeAll()
        }
        projectsNamesAndData.reverse()
        saveProjects(projectsNamesAndData)
        configureTableWithData()
        return projectsNamesAndData
    }
    
    func fetchDataForEachProject(_ projectsData: [[String]]) {
        var projectObjects = [Project]()
        
        for projectsDataIndex in 0...projectsData.count - 1 {
            let name = projectsData[projectsDataIndex][0]
            let email = projectsData[projectsDataIndex][1]
            let authenticator = projectsData[projectsDataIndex][2]
            let averageCredit = projectsData[projectsDataIndex][3]
            let totalCredit = projectsData[projectsDataIndex][4]
            let homePage = projectsData[projectsDataIndex][5]
            projectObjects.append(Project(name: name, email, authenticator, averageCredit, totalCredit, homePage))
        }
        
        for projectObjectsIndex in 0...projectsData.count - 1 {
            let authenticator = projectsData[projectObjectsIndex][2]
            let homePage = projectsData[projectObjectsIndex][5]
            let email = projectsData[projectObjectsIndex][1]
            projectObjects[projectObjectsIndex].fetch(.showUserInfo, authenticator, projectHomePage: homePage, email) { (averageCredit, totalCredit) in
                DispatchQueue.main.sync {
                    self.configureTableWithDataObjects(projectObjects)
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let addedProjects = applicationContext["Added projects"] {
            self.addedProjects = addedProjects as! [[String]]
            configureTableWithData()
        }
        if let _ = applicationContext["Empty list of projects"] {
            self.addedProjectsTable.setNumberOfRows(0, withRowType: "mainRowType")
            saveProjects([[]])
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    private func saveProjects(_ addedProjects: [[String]]) {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(addedProjects, toFile: Project.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Projects successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save projects...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadProjects() -> [[String]]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Project.ArchiveURL.path) as? [[String]]
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
