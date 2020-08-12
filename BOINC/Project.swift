//
//  Project.swift
//  BOINC
//
//  Created by Austin Conlon on 7/30/17.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit
import os.log

class Project: NSObject, NSCoding, XMLParserDelegate {
    var name: String
    var homePage: String
    var username: String
    var password: String?
    
    enum Queries {
        case showUserInfo
    }
    
    var dataFromLookingUpAccount: Data?
    var authenticator: String?
    
    var user = User()
    
    var totalCredit: Float = 0
    var averageCredit: Float = 0
    
    var currentParsedCharacterData: String?
    var isAccumulatingParsedCharacterData = false
    
    var isSeekingAuthenticator = false
    var isSeekingUserName = false
    var isSeekingCountry = false
    var isSeekingAverageCredit = false
    var isSeekingTotalCredit = false
    
    var elementName: String?
    
    struct ElementName {
        static let authenticator = "authenticator"
        static let userName = "name"
        static let country = "country"
        static let averageCredit = "expavg_credit"
        static let totalCredit = "total_credit"
    }
    
    // MARK: - Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("projects")
    
    // MARK: - Initialization
    @objc init(name: String,
               _ email: String = "",
               _ authenticator: String = "",
               _ averageCredit: Float = 0,
               _ totalCredit: Float = 0,
               _ homePage: String = "") {
        self.name = name
        self.username = email
        self.authenticator = authenticator
        self.averageCredit = averageCredit
        self.totalCredit = totalCredit
        self.homePage = homePage
    }

    // MARK: - Keys
    struct PropertyType {
        static let name = "name"
        static let email = "email"
        static let authenticator = "authenticator"
        static let averageCredit = "averageCredit"
        static let totalCredit = "totalCredit"
        static let homePage = "homePage"
    }
    
    // MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyType.name)
        aCoder.encode(username, forKey: PropertyType.email)
        aCoder.encode(authenticator, forKey: PropertyType.authenticator)
        aCoder.encode(homePage, forKey: PropertyType.homePage)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: PropertyType.name) as? String else {
            os_log("Unable to decode the name for a Project object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let email = aDecoder.decodeObject(forKey: PropertyType.email) as? String else {
            os_log("Unable to decode the email for a Project object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let authenticator = aDecoder.decodeObject(forKey: PropertyType.authenticator) as? String else {
            os_log("Unable to decode the authenticator for a Project object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let homePage = aDecoder.decodeObject(forKey: PropertyType.homePage) as? String else {
            os_log("Unable to decode the home page for a Project object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(name: name, email, authenticator, 0, 0, homePage)
    }
    
    // MARK: - MD5 Hash Methods
    // MD5 is required to use BOINC's Web Remote Procedure Calls
    func createHash(_ password: String, _ email: String) -> String {
        let passwordAndEmail = password + email
        let md5Data = MD5(string: passwordAndEmail)
        return md5Data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func MD5(string: String) -> Data {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }
    
    // MARK: - Networking
    func fetchAuthenticator(_ projectHomePage: String, _ email: String, _ password: String, completion: @escaping (String?) -> Void) -> Void {
        let hash = createHash(password, email)
        let URL = generateURLForFetchingAuthenticator(projectHomePage, email, hash)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.dataTask(with: URL) { (data, response, error) in
            self.parseReturnedXML(data!)
            completion(self.authenticator)
        }
        task.resume()
    }
    
    func fetch(_ query: Queries, _ authenticator: String = "", _ projectHomePage: String = "", username: String, completion: @escaping (Float, Float) -> Void) {
        
        let URL = generateURL(query, projectHomePage, authenticator, username)
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: URL) { (data, response, error) in
            self.parseReturnedXML(data!)
            completion(self.averageCredit, self.totalCredit)
        }
        task.resume()
    }
    
    func generateURLForFetchingAuthenticator(_ projectHomePage: String, _ email: String, _ hash: String) -> URL {
        let urlToFetchAuthenticatorFrom = URL(string: projectHomePage + "/lookup_account.php?email_addr=" + email + "&passwd_hash=" + hash)!
        return urlToFetchAuthenticatorFrom
    }
    
    func generateURL(_ query: Queries, _ projectHomePage: String, _ authenticator: String, _ username: String) -> URL {
        var urlToQuery: URL
        if self.name == "World Community Grid" {
            urlToQuery = URL(string: "https://www.worldcommunitygrid.org/stat/viewMemberInfo.do?userName=" + username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! + "&xml=true")!
        } else {
            urlToQuery = URL(string: projectHomePage + "/show_user.php?auth=" + authenticator + "&format=xml")!
        }
        
        return urlToQuery
    }
    
    // MARK: - XMLParser
    func parserDidStartDocument(_ parser: XMLParser) {
        self.averageCredit = 0
        self.totalCredit = 0
    }
    
    func parseReturnedXML(_ data: Data?) {
        let parser = XMLParser(data: data!)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // TODO: Replace boilerplate with a property wrapper.
        switch elementName {
        case ElementName.authenticator:
            self.isSeekingAuthenticator = true
            self.isAccumulatingParsedCharacterData = true
            self.currentParsedCharacterData = ""
        case ElementName.userName:
            self.isSeekingUserName = true
            self.isAccumulatingParsedCharacterData = true
            self.currentParsedCharacterData = ""
        case ElementName.country:
            self.isSeekingCountry = true
            self.isAccumulatingParsedCharacterData = true
            self.currentParsedCharacterData = ""
        case ElementName.averageCredit:
            self.isSeekingAverageCredit = true
            self.isAccumulatingParsedCharacterData = true
            self.currentParsedCharacterData = ""
        case ElementName.totalCredit:
            self.isSeekingTotalCredit = true
            self.isAccumulatingParsedCharacterData = true
            self.currentParsedCharacterData = ""
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.isAccumulatingParsedCharacterData {
            currentParsedCharacterData?.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
        case ElementName.authenticator:
            if self.isSeekingAuthenticator {
                self.authenticator = currentParsedCharacterData
                self.isSeekingAuthenticator = false
            }
        case ElementName.userName:
            if self.isSeekingUserName {
                self.user.name = currentParsedCharacterData
                self.isSeekingUserName = false
            }
        case ElementName.country:
            if self.isSeekingCountry {
                self.user.country = currentParsedCharacterData
                self.isSeekingCountry = false
            }
        case ElementName.averageCredit:
            if self.isSeekingAverageCredit {
                self.averageCredit += Float(currentParsedCharacterData!)!
                self.isSeekingAverageCredit = false
            }
        case ElementName.totalCredit:
            if self.isSeekingTotalCredit {
                self.totalCredit += Float(currentParsedCharacterData!)!
                self.isSeekingTotalCredit = false
            }
        default:
            break
        }
        
        // Stop accumulating parsed character data. We won't start again until specific elements begin.
        self.isAccumulatingParsedCharacterData = false
    }
}
