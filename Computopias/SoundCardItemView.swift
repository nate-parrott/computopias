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
import AsyncDisplayKit

class SoundCardItemView: CardItemView, IQAudioRecorderControllerDelegate, AVAudioPlayerDelegate {
    
    // MARK: Data
    var url: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    var duration: Double? {
        didSet {
            setNeedsDisplay()
        }
    }
    var loop = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var localFilePath: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    var uploadInProgress = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var downloadTask: NSURLSessionDataTask? {
        didSet(oldValue) {
            if let o = oldValue {
                o.cancel()
            }
            setNeedsDisplay()
        }
    }
    
    // MARK: Lifecycke
    override func setup() {
        super.setup()
        opaque = false
    }
    
    deinit {
        downloadTask = nil
    }
    
    // MARK: Layout/UI
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return CGSizeMake(max(2, size.width), size.height)
    }
    var nowPlaying = false {
        didSet {
            setNeedsDisplay()
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
        if editMode && !nowPlaying {
            let actions = UIAlertController(title: "Recording", message: nil, preferredStyle: .ActionSheet)
            let hasAudio = url != nil || localFilePath != nil
            if hasAudio {
                actions.addAction(UIAlertAction(title: "🔈 Play", style: .Default, handler: { (let action) in
                    self.startPlaying()
                }))
            }
            actions.addAction(UIAlertAction(title: "Record", style: .Default, handler: { (let action) in
                self.recordAudio(nil)
            }))
            if hasAudio {
                actions.addAction(UIAlertAction(title: "Clear recording", style: .Default, handler: { (let action) in
                    self.url = nil
                    self.localFilePath = nil
                }))
            }
            
            if loop {
                actions.addAction(UIAlertAction(title: "Disable looping", style: .Default, handler: { (let action) in
                    self.loop = false
                }))
            } else {
                actions.addAction(UIAlertAction(title: "Enable looping", style: .Default, handler: { (let action) in
                    self.loop = true
                }))
            }
            actions.actions.last!.enabled = hasAudio
            
            actions.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: { (let action) in
                
            }))
            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(actions, animated: true, completion: nil)
        } else {
            togglePlayback()
        }
        return true
    }
    // TODO: let people change the title?
    
    override var needsNoView: Bool {
        get {
            return true
        }
    }
    
    func recordAudio(sender: AnyObject?) {
        let controller = IQAudioRecorderController()
        controller.delegate = self
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(controller, animated: true, completion: nil)
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
        let asset = AVAsset(URL: NSURL(fileURLWithPath: filePath))
        duration = Double(CMTimeGetSeconds(asset.duration))
    }
    // MARK: Playback
    func startPlaying() {
        if !nowPlaying { togglePlayback() }
    }
    func stopPlaying() {
        if nowPlaying { togglePlayback() }
    }
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
            _startPlaybackTimePolling()
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
    }
    func _startPlaybackTimePolling() {
        if nowPlaying {
            setNeedsDisplay()
            delay(1, closure: { 
                self._startPlaybackTimePolling()
            })
        }
    }
    
    // MARK: Rendering
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        var attributes = [String: AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = TextCardItemView.font.fontWithSize(generousFontSize)
        attributes[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(alignment.x.textAlignment)
        
        var text = ""
        if nowPlaying {
            if uploadInProgress {
                text = "🔈 Uploading..."
            } else {
                let d = FormatDuration(player?.currentTime ?? 0)
                text = "🔊 \(d)"
            }
        } else if url != nil || localFilePath != nil {
            if downloadTask != nil {
                text = "🔈 Loading..."
            } else {
                let d = FormatDuration(self.duration ?? 0)
                text = "🔈 \(d)"
            }
        } else if editMode {
            text = "🎙 Record"
        } else {
            text = "🔇 Empty"
        }
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    override var alignment: (x: CardItemView.Alignment, y: CardItemView.Alignment) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let string = withParameters as! NSAttributedString
        string.drawVerticallyCenteredInRect(CardItemView.textInsetBoundsForBounds(bounds))
    }
}

private func FormatDuration(d: NSTimeInterval) -> String {
    let minutes = floor(d/60)
    let seconds = d - minutes * 60
    return String(format: "%d:%02d", Int(minutes), Int(seconds))
}
