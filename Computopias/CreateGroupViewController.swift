//
//  CreateGroupViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/3/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CreateGroupViewController: NavigableViewController {
    override var isHome: Bool {
        get {
            return true
        }
    }
    
    override func getTabs() -> [(String, Route)]? {
        return NavigableViewController.homeTabs()
    }
}
