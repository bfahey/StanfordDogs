//
//  DogCell.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/19/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import UIKit

class DogCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
    }
}
