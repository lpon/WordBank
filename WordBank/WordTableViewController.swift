//
//  WordTableViewController.swift
//  WordBank
//
//  Created by Lia Odette on 2017-10-17.
//  Copyright © 2017 Lia Odette Pon. All rights reserved.
//

import UIKit
import os.log
import UserNotifications
import UserNotificationsUI

class WordTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate{
    
    
    // MARK: Properties
    var words = [String: [Word]]()
    var sectionHeadings = [String]()
    var filteredSectionHeadings = [String]()
    var filteredWords = [Word]()
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if loadWords() != nil && loadWords()?.count != 0 {
            words = loadWords()!
        }
        else {
            let hello = Word(name: "Hello")
            let world = Word(name: "World")
            do {
                try hello.setDefinition()
            } catch {
                hello.definition = "Cannot access Oxford Dictionary API"
            }
            
            do {
                try world.setDefinition()
            } catch {
                world.definition = "Cannot access Oxford Dictionary API"
            }
            
            
            
            loadSampleWords(samples: [hello, world])
        }
        
        setSectionHeadings()

        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        triggerNotification()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering() {
            return 1
        }
        else {
            return sectionHeadings.count
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionHeader = sectionHeadings[section]
        if isFiltering() {
            return filteredWords.count
        }
        
        if words[sectionHeader]?.count != nil {
            return words[sectionHeader]!.count
        }
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering() == true {
            return "Search Results"
        }
        else {
            return sectionHeadings[section]
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "WordTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? WordTableViewCell  else {
            fatalError("The dequeued cell is not an instance of WordTableViewCell.")
        }
        
        var word: Word
        
        if isFiltering() {
            word = filteredWords[indexPath.row]
        }
        else {
            // Fetches the appropriate word for the data source layout.
            let sectionHeader = sectionHeadings[indexPath.section]
            word = (words[sectionHeader]?[indexPath.row])!
        }
        
        cell.nameLabel.text = word.name
        
        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
 

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let sectionHeader = sectionHeadings[indexPath.section]
            words[sectionHeader]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        
            if words[sectionHeader]?.count == 0 {
                words.removeValue(forKey: sectionHeader) // remove key-value pair if no more words left
                sectionHeadings.remove(at: indexPath.section) // remove section from list of headings
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade) // delete section from table
            }
            tableView.endUpdates()
            saveWords()
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "ShowDetail" {
            guard let wordDetailViewController = segue.destination as? SavedWordViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedWordCell = sender as? WordTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedWordCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }

            var word: Word
            
            if isFiltering() {
                word = filteredWords[indexPath.row]
            } else {
                let sectionHeader = sectionHeadings[indexPath.section]
                word = (words[sectionHeader]?[indexPath.row])!
            }
            wordDetailViewController.savedWord = word
        }
    }

    
    // MARK: Actions
    
    @IBAction func unwindToWords(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? WordViewController, let word = sourceViewController.word {
            if tableView.indexPathForSelectedRow == nil {
                tableView.beginUpdates()
                
                addWordToWords(word: word)
                let forSection: Int
                let rowNum: Int
                let firstLetter = word.getFirstLetter()
                
                
                // If there is already a section for the word entry
                if sectionHeadings.contains(firstLetter) {
                    forSection = sectionHeadings.index(of: firstLetter)!
                    rowNum = words[firstLetter]!.index(of: word)!
                } else {
                    // If there is not already a section for the word entry
                    var temp = sectionHeadings
                    temp.append(firstLetter)
                    temp.sort()
                    
                    forSection = temp.index(of: firstLetter)!
                    let forSectionIndex = IndexSet(integer: forSection)
                    rowNum = 0
                    
                    tableView.insertSections(forSectionIndex, with: .automatic)
                }
                
                let newIndexPath = IndexPath(row: rowNum, section: forSection)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                setSectionHeadings()
                
                print("Added the new word")
                tableView.endUpdates()
                
                //Save the word entries
                print("Saving the new word")
                saveWords()
            }
        }
    }
    
    @IBAction func triggerNotification() {
        let content = UNMutableNotificationContent()
        
        // Find a random word object
        if let word = randomWord() as? Word {
            
            content.title = "Remember Me?"
            content.subtitle =  word.name
            content.body = word.definition
            content.sound = UNNotificationSound.default()
            
            
            // Configure the trigger for noon reminder
            var dateInfo = DateComponents()
            dateInfo.timeZone =  NSTimeZone.system
            dateInfo.hour = 12
            dateInfo.minute = 30
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
            
            
            // Create the request object
            let request = UNNotificationRequest(identifier: "ReminderRequest", content: content, trigger: trigger)
            
            
            let center = UNUserNotificationCenter.current()
            
            center.add(request) { (error: Error?) in
                if let theError = error {
                    print(theError.localizedDescription)
                }
                
            }
        }
    }
    
    // MARK: Private Methods
    
    private func loadSampleWords(samples: [Word]) {
        for i in 0..<samples.count {
            let word = samples[i]
            addWordToWords(word: word)
            setSectionHeadings()
        }
    }
    
    private func addWordToWords(word: Word) {
        let firstLetter = word.getFirstLetter()
        if words.keys.contains(firstLetter) {
            let values = Array(words.values)
            var wordNames = [String]()
            
            for i in 0..<values.count {
                for j in 0..<values[i].count {
                    wordNames.append(values[i][j].name)
                }
            }
            if wordNames.contains(word.name) == false {
                words[firstLetter]!.append(word)
            }
        }
        else {
            words[firstLetter] = [word]
        }
        
        words[firstLetter]!.sort(by: {$0.name < $1.name})

    }
    
    private func setSectionHeadings() {
        sectionHeadings = words.keys.sorted()
    }
    
    private func saveWords() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(words, toFile: Word.ArchiveURL.path)
        if isSuccessfulSave {
        os_log("Words successfully saved.", log: OSLog.default, type: .debug)
        } else {
        os_log("Failed to save words...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadWords() -> [String: [Word]]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Word.ArchiveURL.path) as? [String: [Word]]
    }

    
    private func randomWord() -> Any {
        let values = Array(words.values)
        var allWords = [Word]()
        
        for i in 0..<values.count {
            for j in 0..<values[i].count {
                allWords.append(values[i][j])
            }
        }
        
        if allWords.count == 0 {
            return -1
        } else {
            let numWordEntries = allWords.count
            let randInt = Int(arc4random_uniform(UInt32(numWordEntries)))
            return allWords[randInt]
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true is the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        let values = Array(words.values)
        var allWords = [Word]()
        
        for i in 0..<values.count {
            for j in 0..<values[i].count {
                allWords.append(values[i][j])
            }
        }
        
        filteredWords = allWords.filter({
            (word: Word) -> Bool in return
            word.name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        // Describes when the Search Controller should begin filtering
        return searchController.isActive && !searchBarIsEmpty()
    }
}

//MARK: UISearchResultsUpdating Delegate

extension WordTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController){
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
}

