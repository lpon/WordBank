//
//  WordViewController.swift
//  WordBank
//
//  Created by Lia Odette on 2017-10-17.
//  Copyright © 2017 Lia Odette Pon. All rights reserved.
//

import UIKit
import os.log

class WordViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate{

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var wordTextField: UITextField!
    @IBOutlet weak var definitionTextView: UITextView!
    
    var word: Word?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wordTextField.delegate = self
        definitionTextView.delegate = self
        
        updateSaveButtonState()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Actions
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
    
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        word = Word(name: textField.text!.capitalized.trimmingCharacters(in: .whitespacesAndNewlines))
        
        word?.setDefinition(textView: definitionTextView)
        
        wordTextField.text = word?.name
        definitionTextView.text = word?.definition
        
        print("Created instance of \(word?.name)")
        
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = wordTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    

    
    
}

