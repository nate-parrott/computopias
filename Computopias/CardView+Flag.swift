//
//  CardView+Flag.swift
//  Computopias
//
//  Created by Nate Parrott on 4/5/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension CardView {
    func showFlagDialog() {
        let name = posterName ?? "this user"
        let sheet = UIAlertController(title: "🚩 Flag or block", message: "If the content on this card is objectionable or discriminatory, you can report this card, block \(name), or report \(name). We'll review anything you report and take action if appropriate.", preferredStyle: .Alert)
        sheet.addAction(UIAlertAction(title: "Flag this card", style: .Default, handler: { (_) in
            self.showReportDialogForItem(Route.Card(hashtag: self.hashtag!, id: self.cardFirebase!.key).url.absoluteString)
        }))
        sheet.addAction(UIAlertAction(title: "Block \(name)", style: .Default, handler: { (_) in
            Data.blockUser(self.poster!)
            self.showMessage("\(name) has been blocked. You won't see posts from them in the app anymore.")
        }))
        sheet.addAction(UIAlertAction(title: "Report and block \(name)", style: .Default, handler: { (_) in
            Data.blockUser(self.poster!)
            self.showMessage("\(name) has been blocked. You won't see posts from them in the app anymore.")
            self.showReportDialogForItem(Route.forProfile(self.poster!).url.absoluteString)
        }))
        sheet.addAction(UIAlertAction(title: "Report \(name)", style: .Default, handler: { (_) in
            self.showReportDialogForItem(Route.forProfile(self.poster!).url.absoluteString)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(sheet, animated: true, completion: nil)
    }
    
    func showReportDialogForItem(url: String) {
        let dialog = UIAlertController(title: "Report", message: "If this card or user posts content that's objectionable or discriminatory, you can report this card. We'll review anything you report and take action if appropriate. If there's anything else you'd like us to know, enter it here.", preferredStyle: .Alert)
        dialog.addTextFieldWithConfigurationHandler { (let field) in
            field.placeholder = "Any extra information (optional)"
        }
        dialog.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { (_) in
            let info = dialog.textFields![0].text ?? ""
            Data.flagItemForReview(url, additionalInfo: info)
        }))
        dialog.addAction(UIAlertAction(title: "Don't report", style: .Cancel, handler: nil))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(dialog, animated: true, completion: nil)

    }
    
    func showMessage(message: String) {
        let dialog = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        dialog.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(dialog, animated: true, completion: nil)
    }
    
    func _hideIfBlocked() {
        if let posterId = poster, let blockedList = Data.blockedUserIDs.value where blockedList.containsObject(posterId) {
            hidden = true
        }
    }
}
