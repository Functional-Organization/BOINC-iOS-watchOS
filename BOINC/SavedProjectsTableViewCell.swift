//
//  SavedProjectsTableViewCell.swift
//  BOINC
//
//  Created by Austin Conlon on 8/2/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import UIKit

class SavedProjectsTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var averageCreditLabel: UILabel!
    @IBOutlet weak var totalCreditLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
