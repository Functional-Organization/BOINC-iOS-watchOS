//
//  NetworkController.swift
//  BOINC
//
//  Created by Austin Conlon on 9/1/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct NetworkController {
    static func urlSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        return URLSession(configuration: configuration)
    }
}
