//
//  ProjectDetail.swift
//  BOINC
//
//  Created by Austin Conlon on 7/30/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit
import os.log
import CryptoKit

class ProjectDetail: NSObject, NSCoding, XMLParserDelegate {
    var name: String
    var homePage: String
    var username: String
    var password: String?
    enum Queries {
        case showUserInfo
    }
    var dataFromLookingUpAccount: Data?
    var authenticator: String?
    var totalCredit: String
    var averageCredit: String
    var elementName: String?
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("projects")
    
    static let session = NetworkController.urlSession()
    
    // MARK: Initialization
    @objc init(name: String, _ email: String = "", _ authenticator: String = "", _ averageCredit: String = "0", _ totalCredit: String = "0", _ homePage: String = "") {
        self.name = name
        self.username = email
        self.authenticator = authenticator
        self.averageCredit = averageCredit
        self.totalCredit = totalCredit
        self.homePage = homePage
    }

    // MARK: Types
    struct PropertyType {
        static let name = "name"
        static let email = "email"
        static let authenticator = "authenticator"
        static let averageCredit = "averageCredit"
        static let totalCredit = "totalCredit"
        static let homePage = "homePage"
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyType.name)
        aCoder.encode(username, forKey: PropertyType.email)
        aCoder.encode(authenticator, forKey: PropertyType.authenticator)
        aCoder.encode(averageCredit, forKey: PropertyType.averageCredit)
        aCoder.encode(totalCredit, forKey: PropertyType.totalCredit)
        aCoder.encode(homePage, forKey: PropertyType.homePage)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: PropertyType.name) as? String else {
            os_log("Unable to decode the name for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let email = aDecoder.decodeObject(forKey: PropertyType.email) as? String else {
            os_log("Unable to decode the email for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let authenticator = aDecoder.decodeObject(forKey: PropertyType.authenticator) as? String else {
            os_log("Unable to decode the authenticator for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let averageCredit = aDecoder.decodeObject(forKey: PropertyType.averageCredit) as? String else {
            os_log("Unable to decode the average credit for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let totalCredit = aDecoder.decodeObject(forKey: PropertyType.totalCredit) as? String else {
            os_log("Unable to decode the total credit for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let homePage = aDecoder.decodeObject(forKey: PropertyType.homePage) as? String else {
            os_log("Unable to decode the home page for a ProjectDetail object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.init(name: name, email, authenticator, averageCredit, totalCredit, homePage)
    }
    
    func createHash(_ password: String, _ email: String) -> String {
        let passwordAndEmail = password + email
        let passwordAndEmailData = Data(passwordAndEmail.utf8)
        return Insecure.MD5.hash(data: passwordAndEmailData).map { String(format: "%02hhx", $0) }.joined()
    }
    
    // MARK: - Networking
    static func loadAuthenticatorData(responseURL: URL, completion: @escaping ([ProjectDetail]?, Error?) -> Void) {
        do {
            session.dataTask(with: responseURL) { (data, response, error) in
                if let data = data {
                    do {
//                        completion(data, error)
                    } catch {
                        completion(nil, error)
                    }
                } else {
                    completion(nil, error)
                }
            }.resume()
        } catch {
            completion(nil, error)
        }
        
    }
    
    func fetchAuthenticator(_ projectHomePage: String, _ email: String, _ password: String, completion: @escaping (String?, Error?) -> Void) -> Void {
        let hash = createHash(password, email)
        if let URL = generateURLForFetchingAuthenticator(projectHomePage, email, hash) {
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let task = session.dataTask(with: URL) { (data, response, error) in
                if let data = data {
                    self.parseReturnedXML(data)
                }
                completion(self.authenticator, error)
            }
            task.resume()
        }
    }
    
    func fetch(_ query: Queries, _ authenticator: String = "", _ projectHomePage: String = "", username: String, completion: @escaping (String, String, Error?) -> Void) {
        let url = generateURL(query, projectHomePage, authenticator, username)
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                self.parseReturnedXML(data)
            }
            completion(self.averageCredit, self.totalCredit, error)
        }
        task.resume()
    }
    
    func generateURLForFetchingAuthenticator(_ projectHomePage: String, _ email: String, _ hash: String) -> URL? {
        let urlToFetchAuthenticatorFrom = URL(string: projectHomePage + "/lookup_account.php?email_addr=" + email + "&passwd_hash=" + hash)
        return urlToFetchAuthenticatorFrom
    }
    
    func generateURL(_ query: Queries, _ projectHomePage: String, _ authenticator: String, _ username: String) -> URL {
        var urlToQuery: URL
        if self.name == "World Community Grid" {
            urlToQuery = URL(string: "https://www.worldcommunitygrid.org/stat/viewMemberInfo.do?userName=" + username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! + "&xml=true")!
        } else {
            urlToQuery = URL(string: projectHomePage + "/show_user.php?auth=" + authenticator + "&format=xml")!
            print(urlToQuery.absoluteURL)
        }
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
        } else if elementName == "total_credit" || elementName == "Points" {
            totalCredit = String()
        } else if elementName == "expavg_credit" || elementName == "PointsPerDay" {
            averageCredit = String()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if !data.isEmpty {
            if elementName == "authenticator" {
                authenticator = data
            }
            else if elementName == "total_credit" || elementName == "Points" {
                totalCredit = data
            }
            else if elementName == "expavg_credit" || elementName == "PointsPerDay" {
                averageCredit = data
                parser.abortParsing()
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { }
}
