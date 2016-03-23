//
//  ButtonCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import SafariServices

class ButtonCardItemView: CardItemView {
    let button = UIButton()
    override func setup() {
        super.setup()
        addSubview(button)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.5)
        button.layer.cornerRadius = CardView.rounding
        button.userInteractionEnabled = false
        button.setTitle("Tap to edit...", forState: .Normal)
        button.titleLabel!.font = TextCardItemView.font.fontWithSize(12)
    }
    
    override var defaultSize: GridSize {
        return GridSize(width: 3, height: 1)
    }
    
    var link = ""
    
    override func tapped() {
        if editMode {
            let editor = UIAlertController(title: "Edit Button", message: "Choose a title and a link", preferredStyle: .Alert)
            editor.addTextFieldWithConfigurationHandler({ (let field) in
                field.placeholder = "Button title"
                field.text = self.button.titleForState(.Normal) ?? ""
                if field.text == "Tap to edit..." {
                    field.text = ""
                }
            })
            editor.addTextFieldWithConfigurationHandler({ (let field) in
                field.placeholder = "Link"
                field.text = self.link
            })
            editor.addAction(UIAlertAction(title: "Done", style: .Default, handler: { (_) in
                let title = editor.textFields![0].text!
                self.button.setTitle(title, forState: .Normal)
                self.link = editor.textFields![1].text ?? ""
            }))
            presentViewController(editor)
        } else {
            if let firstChar = link.characters.first {
                if firstChar == "#".characters.first! || firstChar == "@".characters.first! {
                    NavViewController.shared.navigate(link)
                } else {
                    if link.componentsSeparatedByString(" ").count > 1 || link.componentsSeparatedByString(".").count == 1 {
                        // not a URL?
                        let alertVC = UIAlertController(title: nil, message: link, preferredStyle: .Alert)
                        alertVC.addAction(UIAlertAction(title: "Done", style: .Default, handler: { (_) in
                            
                        }))
                        presentViewController(alertVC)
                    } else {
                        if var url = NSURL(string: link) {
                            if url.scheme == "" {
                                url = NSURL(string: "http://" + link)!
                            }
                            let safari = SFSafariViewController(URL: url)
                            presentViewController(safari)
                        }
                    }
                }
            }
        }
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        link = json["link"] as? String ?? ""
        button.setTitle(json["title"] as? String ?? "", forState: .Normal)
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "button"
        j["title"] = button.titleForState(.Normal) ?? ""
        j["link"] = link
        return j
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRectInset(bounds, 2, 2)
    }
}
