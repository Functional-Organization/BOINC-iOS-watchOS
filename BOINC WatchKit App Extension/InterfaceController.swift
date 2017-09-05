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

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet var addedProjectsTable: WKInterfaceTable!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        // Configure interface objects here.
        if let savedProjects = loadProjects() { // Load any saved projects.
            configureTableWithData(savedProjects)
            var projectsToUpdateWithNewCredits = [Project]()
            for index in 0...savedProjects.count - 1 {
//                projectsToUpdateWithNewCredits.append()
            }
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
    
    func configureTableWithData(_ projectsData: [[String]]) {
        self.addedProjectsTable.setNumberOfRows(projectsData.count, withRowType: "mainRowType")
        if projectsData.count > 0 {
            var projectsDataToBeSaved = [[String]]()
            var projectDataToBeSaved = [String]()
            for projectIndex in 0...projectsData.count - 1 {
                let theRow = self.addedProjectsTable.rowController(at: projectIndex) as! AddedProjectsRowController
                theRow.nameLabel.setText(projectsData[projectIndex][0])
                theRow.averageCreditLabel.setText(projectsData[projectIndex][1])
                theRow.totalCreditLabel.setText(projectsData[projectIndex][2])
                for projectAttribute in 0...4 {
                    projectDataToBeSaved.append(projectsData[projectIndex][projectAttribute])
                }
                projectsDataToBeSaved.append(projectDataToBeSaved)
            }
            saveProjects(projectsDataToBeSaved)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let applicationContext = applicationContext as! [String : [String]]
        var projectData = [String]()
        var projectsNamesAndData = [[String]]()
        
        for (projectName, _) in applicationContext {
            for index in 0...4 { // Populate an array of the project's name, average credit, and total credit.
                let projectDatum = [applicationContext[projectName]![index]]
                projectData += projectDatum
            }
            projectsNamesAndData.append(projectData)
            projectData.removeAll()
        }
        projectsNamesAndData.reverse()
        configureTableWithData(projectsNamesAndData)
        projectsNamesAndData.removeAll()
        
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
    
    private func fetchCreditsForEachProject() {
        
    }
}
