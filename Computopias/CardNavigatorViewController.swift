//
//  CardNavigatorViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardNavigatorViewController: UIViewController {
    var cardNav: CardNavigatorView! {
        get {
            return view as! CardNavigatorView
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        cardNav.cardSize = CardView.CardSize
        cardNav.addStack(ActivityCardStack())
        cardNav.backgroundColor = UIColor.whiteColor()
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
