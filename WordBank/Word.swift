//  Word.swift
//  WordBank
//
//  Created by Lia Odette on 2017-10-17.
//  Copyright © 2017 Lia Odette Pon. All rights reserved.
//

import Foundation
import UIKit
import os.log


class Word: NSObject, NSCoding {
    
    // MARK: Properties 
    
    var name: String
    var definition: String
    
    init(name: String) {
        self.name = name.capitalized
        self.definition = ""
    }
    
    struct PropertyKey {
        static let name = "name"
        static let definition = "definition"
    }
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("words")
    
    
    // MARK: Private methods
    
    enum DefinitionError: Error {
        case NoKeyNoIdAvaliable
    }
    
    func setDefinition(textView: UITextView? = nil) throws {
        var newDeff: String = ""
        
        let path = Bundle.main.path(forResource: "OxfordAPIInfo", ofType: "txt")
        
        var key = ""
        var  id = ""
        
        do {
            // Get the contents
            let contents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue)
            let arr = contents.components(separatedBy: " ")
            id = arr[0].trimmingCharacters(in: .whitespacesAndNewlines)
            key = arr[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        catch let error as NSError {
            print("Ooops! let path = (NSTemp... did not work: \(error)")
            throw DefinitionError.NoKeyNoIdAvaliable
        }
        
        let appId = id
        let appKey = key
        let language = "en"
        let wordToDefine = self.name
        let word_id = wordToDefine.lowercased().replacingOccurrences(of: " ", with: "_", options: .literal, range: nil)
        let url = URL(string: "https://od-api.oxforddictionaries.com:443/api/v1/entries/\(language)/\(word_id)")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(appId, forHTTPHeaderField: "app_id")
        request.addValue(appKey, forHTTPHeaderField: "app_key")
        
        
        let session = URLSession.shared
        _ = session.dataTask(with: request, completionHandler: { data, response, error in
            if let _ = response,
                let data = data,
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {

                // Begin Parsing
                var allDeffs =  [String : [String]]()
                var lexicalCategory = String()
                var curDeffs = [String]()
                
                let json = jsonData as? [String: Any]
                
                let results = json?["results"] as? [[String: Any]]
                if let lexicalEntries = results?[0]["lexicalEntries"] as? [[String: Any?]] {
                    for i in 0..<lexicalEntries.count {
                        // Find Lexical Category
                        lexicalCategory = lexicalEntries[i]["lexicalCategory"] as! String
                        
                        // Gather Definitions
                        let entries = lexicalEntries[i]["entries"] as? [[String: Any?]]
                        if let senses = entries?[0]["senses"] as? [[String: Any?]] {
                            for j in 0..<senses.count {
                                if let deffSection = senses[j]["definitions"] as? [String] {
                                    curDeffs.append(deffSection[0])
                                }
                            }
                        }
                        allDeffs[lexicalCategory] = curDeffs
                        // Clear variables
                        lexicalCategory = String()
                        curDeffs = [String]()
                    }
                }
                
                newDeff = self.formatDefs(allDeffs: allDeffs)
                
            } else {
                newDeff = "Cannot find any definitions for \(self.name)"

                print(error)
                print(NSString.init(data: data!, encoding: String.Encoding.utf8.rawValue))
            }
            // Must assign definition on main thread
            DispatchQueue.main.async(execute: {
                self.definition = newDeff
                if textView != nil {
                    textView?.text = self.definition
                }
            })
        }).resume()
    }

    func getFirstLetter() -> String {
        return String(self.name[self.name.startIndex])
    }
    
    private func formatDefs(allDeffs: [String: [String]]) -> String {
        var formattedDefs: String = ""
        
        for (key, value) in allDeffs {
            formattedDefs += "\n\n Lexical category: " + key + "\n\n"
            
            for i in 0..<value.count {
                formattedDefs += "\(i + 1)) " + value[i] + "\n"
            }
        }
        return formattedDefs.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(definition, forKey: PropertyKey.definition)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for a Word object.", log: OSLog.default, type: .debug)
            return nil
        }
        self.init(name: name)
        
        do {
            try setDefinition()
        }
        catch {
            self.definition = "Cannot access the Oxford Dictionary API"
        }
    }
    
    
    
}
