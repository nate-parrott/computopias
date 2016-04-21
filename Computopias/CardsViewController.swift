//
//  CardsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardsViewController: NavigableViewController, UICollectionViewController {
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: Models
    class Item {
        var cellIdentifier: String! { get { return nil } }
        func populateCell(cell: UICollectionViewCell) {}
    }
    class CardItem: Item {
        override var cellIdentifier: String {
            get {
                return "CardItem"
            }
        }
        override func populateCell(cell: UICollectionViewCell) {
            
        }
        var cardID: String!
        var hashtag: String?
    }
}
