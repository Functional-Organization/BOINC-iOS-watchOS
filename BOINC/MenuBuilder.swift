//
//  MenuBuilder.swift
//  BOINC
//
//  Created by Benny Pham on 1/28/21.
//  Copyright © 2021 Austin Conlon. All rights reserved.
//

import UIKit

extension AppDelegate {
    
    
    // UIMenuBuilder objects build main menu system and context menu
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        
        // Ensure that the builder is modifying the menu bar system
        guard builder.system == UIMenuSystem.main else { return }
        
        
        // Adding a new command to refresh with Command-R shortcut key
        // Menu system reads the input as case-insensitive but displays value in uppercase
        let refreshCommand = UIKeyCommand(title: "Refresh",
                                          action: #selector(refreshProject),
                                          input: "r",
                                          modifierFlags: [.command])
        
        
        // Can't add instances of UIAction, UICommand, and UIKeyCommand directly to menu system
        // Have to create UIMenu as an object, add the menu object to menu system
        let menuOptions = UIMenu(title: "",
                                 options: .displayInline,
                                 children: [refreshCommand])
        
        
        // Insert menuOptions at the start of the File menu
        builder.insertChild(menuOptions, atStartOfMenu: .file)
    }
    
    
    // The action posts a refresh project notification that SavedProjectsTableViewController handles
    @objc func refreshProject() {
        NotificationCenter.default.post(name: .refreshProject, object: self)
    }
    
}
