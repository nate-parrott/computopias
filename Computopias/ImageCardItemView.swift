//
//  ImageCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import MobileCoreServices
import AsyncDisplayKit

class ImageCardItemView: CardItemView, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    override func setup() {
        super.setup()
        addSubnode(imageNode)
        imageNode.backgroundColor = UIColor(white: 0.1, alpha: 0.7)
        imageNode.contentMode = .ScaleAspectFill
        imageNode.clipsToBounds = true
        imageNode.layerBacked = true
        imageNode.cornerRadius = CardView.rounding
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if editMode && !_uploadInProgress {
            insertMedia()
            return true
        }
        return false
    }
    
    override func onInsert() {
        super.onInsert()
        insertMedia()
    }
    
    override func layout() {
        super.layout()
        imageNode.frame = bounds
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(-1, 6)
        }
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        url = json["url"] as? String
        if let u = url, let uu = NSURL(string: u) {
            imageNode.URL = uu
        }
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        if let u = url {
            j["url"] = u
        }
        j["type"] = "image"
        return j
    }
    
    var url: String?
    let imageNode = ASNetworkImageNode()
    
    func insertMedia() {
        let actionSheet = UIAlertController(title: NSLocalizedString("Insert photo from…", comment: ""), message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .Default, handler: { (_) -> Void in
            self.insertMedia(.PhotoLibrary)
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .Default, handler: { (_) -> Void in
            self.insertMedia(.Camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "Image Search", style: .Default, handler: { (_) in
            self.doImageSearch()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Never mind", comment: ""), style: .Cancel, handler: nil))
        presentViewController(actionSheet)
    }
    
    func insertMedia(source: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeImage as String] // , kUTTypeMovie as String]
        picker.sourceType = source
        picker.delegate = self
        presentViewController(picker)
    }
    
    func doImageSearch() {
        let searchVC = ImageSearchViewController()
        searchVC.onImagePicked = {
            [weak self]
            image in
            self?.insertImage(image)
        }
        let nav = UINavigationController(rootViewController: searchVC)
        presentViewController(nav)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            insertImage(image)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        if url == nil {
            removeFromSupernode()
        }
    }
    
    var _uploadInProgress = false
    func insertImage(image: UIImage) {
        imageNode.image = nil
        url = nil
        let resized = image.resizedWithMaxDimension(600)
        _uploadInProgress = true
        Assets.uploadAsset(UIImageJPEGRepresentation(resized, 0.5)!, contentType: "image/jpeg") { (url, error) -> () in
            mainThread({ () -> Void in
                self._uploadInProgress = false
                if let u = url {
                    self.url = u.absoluteString
                    self.imageNode.image = resized
                }
            })
        }
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
}
