//
//  MapCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AsyncDisplayKit
import LocationPicker

class MapCardItemView: CardItemView, CLLocationManagerDelegate {
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        let region = mapNode.region
        j["type"] = "map"
        j["lat"] = region.center.latitude
        j["lon"] = region.center.longitude
        j["lat_delta"] = region.span.latitudeDelta
        j["lon_delta"] =  region.span.longitudeDelta
        if let t = labelText {
            j["label_text"] = t
        }
        if let u = locationURL {
            j["location_url"] = u
        }
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let lat = json["lat"] as? Double, let lon = json["lon"] as? Double, let latDelta = json["lat_delta"] as? Double, let lonDelta = json["lon_delta"] as? Double {
            let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, lon), MKCoordinateSpanMake(latDelta, lonDelta))
            mapNode.region = region
        }
        labelText = json["label_text"] as? String
        locationURL = json["location_url"] as? String
    }
    override func setup() {
        super.setup()
        mapNode.frame = CGRectMake(0, 0, 100, 100)
        mapNode.preferredFrameSize = CGSizeMake(100, 100)
        mapNode.measure(CGSizeMake(100, 100))
        
        let t = labelText
        labelText = t
        
        addSubnode(mapNode)
        addSubnode(pin)
        pin.frame = CGRectMake(0, 0, 8, 8)
        pin.backgroundColor = UIColor.redColor()
        pin.borderWidth = 2
        pin.borderColor = UIColor.whiteColor().CGColor
        pin.cornerRadius = 4
        
        label.layerBacked = true
        mapNode.addSubnode(label)
        label.backgroundColor = UIColor(white: 0.1, alpha: 0.4)
        label.padding = 4
        
        mapNode.cornerRadius = CardView.rounding
        
        clipsToBounds = true
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(3, 3)
        }
    }
    
    override func prepareToEditWithExistingTemplate() {
        super.prepareToEditWithExistingTemplate()
        _locate()
    }
    
    override func prepareToEditTemplate() {
        super.prepareToEditTemplate()
        _locate()
    }
    
    let locationMgr = CLLocationManager()
    func _locate() {
        labelText = nil
        locationURL = nil
        locationMgr.delegate = self
        locationMgr.requestWhenInUseAuthorization()
        if let loc = locationMgr.location {
            mapNode.region = MKCoordinateRegionMake(loc.coordinate, MKCoordinateSpanMake(0.01, 0.01))
        } else {
            locationMgr.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let l = locations.first {
            centerOnCoordinate(l.coordinate)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if editMode {
            /*let vc = MapEditVC()
            vc.map = MKMapView()
            vc.showRadius = true
            NPSoftModalPresentationController.presentViewController(vc)
            vc.onHide = {
                let region = vc.map.region
                self.mapNode.region = region
            }*/
            let picker = LocationPickerViewController()
            
            let loc = CLLocation(latitude: mapNode.region.center.latitude, longitude: mapNode.region.center.longitude)
            picker.location = Location(name: labelText ?? "", placemark: MKPlacemark(coordinate: loc.coordinate, addressDictionary: nil))
            picker.searchBarPlaceholder = "Search or long-press the map"
            picker.showCurrentLocationInitially = false
            picker.useCurrentLocationAsHint = true
            picker.showCurrentLocationButton = true
            picker.mapType = .Standard
            picker.completion = { [weak self] locationOpt in
                if let s = self, loc = locationOpt {
                    s.centerOnCoordinate(loc.coordinate)
                    s.labelText = loc.name
                }
            }
            NPSoftModalPresentationController.presentViewController(UINavigationController(rootViewController: picker))
        } else {
            let vc = MapEditVC()
            vc.map = MKMapView()
            vc.map.region = mapNode.region
            vc.showShare = true
            vc.map.addAnnotation(CoordinateAnnotation(coord: mapNode.region.center))
            NPSoftModalPresentationController.presentViewController(vc)
        }
        return true
    }
    
    func centerOnCoordinate(coord: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMake(coord, MKCoordinateSpanMake(0.01, 0.01))
        let options = mapNode.options.copy() as! MKMapSnapshotOptions
        options.region = region
        mapNode.options = options
    }
    
    let mapNode = ASMapNode()
    let pin = ASDisplayNode()
    let label = ASLabelNode()
    
    var labelText: String? {
        didSet {
            label.hidden = labelText == nil || labelText == ""
            if !label.hidden {
                label.content = ASLabelNode.Content(font: TextCardItemView.boldFont.fontWithSize(13), color: UIColor.whiteColor(), alignment: .Center, text: labelText ?? "")
            }
        }
    }
    var locationURL: String?
    
    override func layout() {
        super.layout()
        if !CGSizeEqualToSize(insetBounds.size, CGSizeZero) {
            mapNode.frame = insetBounds
        }
        pin.position = bounds.center
        
        let labelHeight: CGFloat = min(mapNode.bounds.size.height, 60)
        label.frame = CGRectMake(0, mapNode.bounds.size.height - labelHeight, mapNode.bounds.size.width, labelHeight)
    }
    
    class CoordinateAnnotation: NSObject, MKAnnotation {
        init(coord: CLLocationCoordinate2D) {
            coordinate = coord
        }
        var coordinate: CLLocationCoordinate2D
    }
    
    class MapEditVC: UIViewController {
        var map: MKMapView!
        let pin = UIView()
        let toolbar = UIToolbar()
        var showRadius = false
        var showShare = false
        var radiusView = UIView()
        override func viewDidLoad() {
            super.viewDidLoad()
            view.addSubview(map)
            if showRadius {
                view.addSubview(pin)
                pin.frame = CGRectMake(0, 0, 8, 8)
                pin.backgroundColor = UIColor.redColor()
                pin.layer.borderWidth = 2
                pin.layer.borderColor = UIColor.whiteColor().CGColor
                pin.layer.cornerRadius = 4
                pin.userInteractionEnabled = false
            }
            if showShare {
                toolbar.barStyle = .Default
                toolbar.sizeToFit()
                view.addSubview(toolbar)
                toolbar.items = [UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(MapEditVC.share(_:)))]
                let item = UIBarButtonItem(borderedWithTitle: "Open in Maps", target: nil, action: #selector(MapEditVC.share(_:)))
                // toolbar.items = [UIBarButtonItem(ti)]
                toolbar.items = [item]
            }
            if showRadius {
                radiusView.backgroundColor = UIColor.clearColor()
                radiusView.layer.borderWidth = 3
                radiusView.layer.borderColor = UIColor(red: 0.3, green: 0.3, blue: 1, alpha: 0.7).CGColor
                radiusView.userInteractionEnabled = false
                view.addSubview(radiusView)
            }
        }
        func share(sender: UIBarButtonItem) {
            if let annotation = map.annotations.first as? CoordinateAnnotation {
                let placemark = MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.openInMapsWithLaunchOptions(nil)
                
                /*let lat = annotation.coordinate.latitude
                let lon = annotation.coordinate.longitude
                let item = NSURL(string: "https://maps.apple.com?q=\(lat),\(lon)")!
                
                let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                presentViewController(activity, animated: true, completion: nil)*/
            }
        }
        override func loadView() {
            view = UIView()
        }
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            if map.superview == view {
                map.frame = view.bounds
            }
            toolbar.frame = CGRectMake(0, view.bounds.size.height - toolbar.frame.size.height, view.bounds.size.width, toolbar.frame.size.height)
            pin.center = view.bounds.center
            
            let radiusSize = min(view.bounds.size.width, view.bounds.size.height) * 0.8
            radiusView.bounds = CGRectMake(0, 0, radiusSize, radiusSize)
            radiusView.layer.cornerRadius = radiusSize/2
            radiusView.center = view.bounds.center
        }
        override func viewWillDisappear(animated: Bool) {
            super.viewWillDisappear(animated)
            if let h = onHide {
                h()
            }
        }
        var onHide: (() -> ())!
        
        override func prefersStatusBarHidden() -> Bool {
            return true
        }
    }
}
