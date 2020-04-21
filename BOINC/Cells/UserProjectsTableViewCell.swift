//
//  UserProjectsTableViewCell.swift
//  BOINC
//
//  Created by Austin Conlon on 8/2/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit

class UserProjectsTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var averageCreditLabel: UILabel!
    @IBOutlet weak var totalCreditLabel: UILabel!
    
    static let reuseIdentifier = "userProjectsTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
