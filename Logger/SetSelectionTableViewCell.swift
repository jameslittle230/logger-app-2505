//
//  SetSelectionTableViewCell.swift
//  Logger
//
//  Created by James Little on 11/30/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class SetSelectionTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var logPreviewImage: UIImageView!
    @IBOutlet weak var setTitle: UILabel!
    @IBOutlet weak var setDescription: UILabel!
}
