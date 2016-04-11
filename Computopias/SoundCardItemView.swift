//
//  SoundCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import IQAudioRecorderController
import AVFoundation

class SoundCardItemView: CardItemView /*, IQAudioRecorderControllerDelegate, AVAudioPlayerDelegate*/ {
    /*
    // MARK: Data
    var url: String? {
        didSet {
            _updateText()
        }
    }
    var duration: Double?
    var loop = false {
        didSet {
            _updateText()
            UIMenuController.sharedMenuController().update()
        }
    }
    var localFilePath: String? {
        didSet {
            _updateText()
        }
    }
    var uploadInProgress = false {
        didSet {
            _updateText()
        }
    }
    var downloadTask: NSURLSessionDataTask? {
        didSet(oldValue) {
            if let o = oldValue {
                o.cancel()
            }
            _updateText()
        }
    }
    
    // MARK: Lifecycke
    
    override func setup() {
        super.setup()
        label.font = TextCardItemView.font
        view.addSubview(label)
        label.textAlignment = .Center
        label.layer.cornerRadius = CardView.rounding
        label.clipsToBounds = true
        
        addSubview(loader)
        loader.hidesWhenStopped =  true
        loader.stopAnimating()
        
        _updateText()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SoundCardItemView._menuWillHide), name: UIMenuControllerWillHideMenuNotification, object: UIMenuController.sharedMenuController())
    }
    
    deinit {
        downloadTask = nil
    }
    
    // MARK: Layout/UI
    let label = UILabel()
    let loader = UIActivityIndicatorView()
    override func layout() {
        super.layout()
        label.frame = textInsetBounds
        label.layer.cornerRadius = CardView.rounding
        label.font = TextCardItemView.font.fontWithSize(generousFontSize)
        loader.center = bounds.center
    }
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    func _updateText() {
        UIMenuController.sharedMenuController().update()
        if nowPlaying {
            label.text = "🔊"
        } else if url != nil || localFilePath != nil {
            label.text = "🔈"
        } else {
            label.text = "🔇"
        }
        backgroundColor = nowPlaying ? Appearance.transparentWhite : nil
        if uploadInProgress || downloadTask != nil {
            loader.startAnimating()
        } else {
            loader.stopAnimating()
        }
    }
    var nowPlaying = false {
        didSet {
            _updateText()
        }
    }
    // MARK: Json
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "sound"
        if let u = url {
            j["url"] = u
        }
        if let d = duration {
            j["duration"] = d
        }
        j["loop"] = loop
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        url = json["url"] as? String ?? url
        loop = json["loop"] as? Bool ?? loop
        duration = json["duration"] as? Double ?? duration
    }
    // MARK: Interaction
    override func tapped() -> Bool {
        super.tapped()
        if editMode {
            delay(0.1, closure: {
                let menuController = UIMenuController.sharedMenuController()
                                
                let recordAudioMenuItem = UIMenuItem(title: "Record", action: #selector(SoundCardItemView.recordAudio))
                let clearAudioMenuItem = UIMenuItem(title: "Clear recording", action: #selector(SoundCardItemView.clearAudio))
                let enableLoop = UIMenuItem(title: "Loop", action: #selector(SoundCardItemView.enableLoop))
                let disableLoop = UIMenuItem(title: "✅ Loop", action: #selector(SoundCardItemView.disableLoop))
                
                menuController.setMenuVisible(false, animated: true)

                self._menuLastShown = CFAbsoluteTimeGetCurrent()
                self.becomeFirstResponder()
                
                menuController.menuItems = [recordAudioMenuItem, clearAudioMenuItem, enableLoop, disableLoop]
                // menuController.setTargetRect(self.bounds, inView: self)
                menuController.setMenuVisible(true, animated: true)
                
            })
        }
        togglePlayback()
        return true
    }
    var _menuLastShown: CFAbsoluteTime?
    func _menuWillHide(notif: NSNotification) {
        if let m = _menuLastShown where CFAbsoluteTimeGetCurrent() - m < 1 {
            let menu = notif.object as! UIMenuController
            menu.menuVisible = true
        }
    }
    // TODO: let people change the title?
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return super.resignFirstResponder()
    }
    
    func recordAudio(sender: AnyObject) {
        let controller = IQAudioRecorderController()
        controller.delegate = self
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(controller, animated: true, completion: nil)
    }
    
    func clearAudio(sender:  AnyObject) {
        url = nil
    }
    
    func enableLoop(sender: AnyObject) {
        loop = true
    }
    
    func disableLoop(sender: AnyObject) {
        loop = false
    }
    
    func audioRecorderController(controller: IQAudioRecorderController!, didFinishWithAudioAtPath filePath: String!) {
        uploadInProgress = true
        localFilePath = filePath
        Assets.uploadAsset(NSData(contentsOfFile: filePath)!, contentType: "audio/m4a") { [weak self] (url, error) in
            if let u = url {
                self?.url = u.absoluteString
            }
            self?.uploadInProgress = false
        }
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if editMode {
            if action == #selector(SoundCardItemView.recordAudio) {
                return true
            }
            if action == #selector(SoundCardItemView.clearAudio) {
                return url != nil
            }
            if action == #selector(SoundCardItemView.enableLoop) {
                return !loop
            }
            if action == #selector(SoundCardItemView.disableLoop) {
                return loop
            }
        }
        return super.canPerformAction(action, withSender: sender!)
    }
    // MARK: Playback
    var _shouldPlayWhenAvailable = false
    func togglePlayback() {
        if player?.playing ?? false || _shouldPlayWhenAvailable {
            // stop playback:
            downloadTask = nil
            nowPlaying = false
            player?.stop()
            player = nil
            _shouldPlayWhenAvailable = false
        } else {
            // start playback:
            nowPlaying = true
            _shouldPlayWhenAvailable = true
            _tryPlay()
        }
    }
    func _tryPlay() {
        if let path = localFilePath, let player_ = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path)) {
            // play now:
            _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            _ = try? AVAudioSession.sharedInstance().setActive(true)
            player = player_
            player_.delegate = self
            player_.play()
            _shouldPlayWhenAvailable = false
        } else if let url_ = url {
            // download, then play
            _shouldPlayWhenAvailable = true
            downloadTask = Assets.fetch(NSURL(string: url_)!, callback: { [weak self] (dataOpt: NSData?, errorOpt: NSError?) in
                if let e = errorOpt {
                    print("Sound fetch error: \(e)")
                }
                
                mainThread({ 
                    self?.downloadTask = nil
                })
                if let data = dataOpt {
                    let filename = NSUUID().UUIDString + ".m4a"
                    let tempPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(filename)
                    try! data.writeToFile(tempPath, options: [])
                    mainThread({
                        self?.localFilePath = tempPath
                        if let s = self where s._shouldPlayWhenAvailable {
                            s._tryPlay()
                        }
                    })
                }
            })
        } else {
            // nothing to play
            nowPlaying = false
            _shouldPlayWhenAvailable = false
        }
    }
    var player: AVAudioPlayer?
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        nowPlaying = false
    }
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if flag && loop {
            player.currentTime = 0
            player.play()
        } else {
            nowPlaying = false
        }
    }*/
}
