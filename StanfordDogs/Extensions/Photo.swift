//
//  Photo.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/19/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import CoreData
import UIKit

extension Photo {
    var image: UIImage? {
        guard let data = data else { return nil }
        return UIImage(data: data)
    }
}
