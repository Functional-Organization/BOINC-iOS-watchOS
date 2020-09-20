//
//  DetailView.swift
//  BOINC
//
//  Created by Austin Conlon on 8/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    let project: ProjectDetail
    
    var body: some View {
        List {
            VStack {
                Text(project.name ?? "")
                Text(project.country ?? "")
            }
        }
        .navigationBarTitle(project.name)
    }
}
