//
//  AddProjectTableViewController.swift
//  BOINC
//
//  Created by Austin Conlon on 7/25/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import UIKit

class AddProjectTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        return projects.count
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectTableViewCell", for: indexPath) as? AddProjectTableViewCell else {
            fatalError("The dequeued cell is not an instance of ProjectTableViewCell.")
        }
        cell.nameLabel.text = projects[indexPath.row].0
        return cell
    }
     
    // MARK: - Navigation
     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let projectViewController = segue.destination as? ProjectViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        projectViewController.selectedRow = tableView.indexPathForSelectedRow!.row
        projectViewController.title = projects[projectViewController.selectedRow!].0
    }

}
