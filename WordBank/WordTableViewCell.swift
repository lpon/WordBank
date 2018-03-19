//
//  WordTableViewCell.swift
//  WordBank
//
//  Created by Lia Odette on 2017-10-17.
//  Copyright © 2017 Lia Odette Pon. All rights reserved.
//

import UIKit

class WordTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
