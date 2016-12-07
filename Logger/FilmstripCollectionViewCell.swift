//
//  FilmstripCollectionViewCell.swift
//  Logger
//
//  Created by James Little on 12/6/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class FilmstripCollectionViewCell: UICollectionViewCell {
    
    var logImageView: UIImageView = UIImageView()
    
    override func awakeFromNib() {
        logImageView = UIImageView(frame: contentView.frame)
        logImageView.contentMode = .scaleAspectFill
        logImageView.clipsToBounds = true
        contentView.addSubview(logImageView)
    }
}
