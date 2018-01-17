//
//  SavedWordViewController.swift
//  WordBank
//
//  Created by Lia Odette on 2017-10-17.
//  Copyright © 2017 Lia Odette Pon. All rights reserved.
//

import UIKit

class SavedWordViewController: UIViewController, UITextViewDelegate{
    
    // MARK: Properties
    
    @IBOutlet weak var savedWordLabel: UILabel!
    
    @IBOutlet weak var savedDefinitionTextView: UITextView!
    
    var savedWord: Word?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        savedDefinitionTextView.delegate = self
        savedWordLabel.text = savedWord?.name
        savedDefinitionTextView.text = savedWord?.definition

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
