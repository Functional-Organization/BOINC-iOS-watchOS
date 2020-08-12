//
//  ProjectDetail.swift
//  BOINC
//
//  Created by Austin Conlon on 8/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct ProjectDetail: View {
    let project: Project
    
    var body: some View {
        List {
            VStack {
                Text(project.user.name)
                Text(project.user.country)
            }
        }
        .navigationBarTitle(project.name)
    }
}
