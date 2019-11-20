//
//  DataControllerContainer.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/18/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import Foundation

/// Designates an object that contains a `DataController`.
protocol DataControllerContainer {
    var dataController: DataController! { get set }
}
