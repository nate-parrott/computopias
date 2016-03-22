//
//  HashtagListViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class HashtagListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var hashtags = ["turndown", "forwhat"] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var onPickQuery: (String -> ())?

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! HashtagCell
        cell.label.text = hashtags[indexPath.item]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.size.width, 44)
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cb = onPickQuery {
            cb(hashtags[indexPath.item])
        }
    }
}

class HashtagCell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
}
