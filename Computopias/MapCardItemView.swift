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

class MapCardItemView: CardItemView, CLLocationManagerDelegate {
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "map"
        j["lat"] = map.centerCoordinate.latitude
        j["lon"] = map.centerCoordinate.longitude
        j["lat_delta"] = map.region.span.latitudeDelta
        j["lon_delta"] =  map.region.span.longitudeDelta
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let lat = json["lat"] as? Double, let lon = json["lon"] as? Double, let latDelta = json["lat_delta"] as? Double, let lonDelta = json["lon_delta"] as? Double {
            let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, lon), MKCoordinateSpanMake(latDelta, lonDelta))
            map.setRegion(region, animated: false)
        }
    }
    override func setup() {
        super.setup()
        addSubview(map)
        map.showsUserLocation = true
        map.userInteractionEnabled = false
        addSubview(pin)
        pin.frame = CGRectMake(0, 0, 8, 8)
        pin.backgroundColor = UIColor.redColor()
        pin.layer.borderWidth = 2
        pin.layer.borderColor = UIColor.whiteColor().CGColor
        pin.layer.cornerRadius = 4
        
        map.layer.cornerRadius = CardView.rounding
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
        locationMgr.delegate = self
        locationMgr.requestWhenInUseAuthorization()
        if let loc = locationMgr.location {
            let region = MKCoordinateRegionMake(loc.coordinate, MKCoordinateSpanMake(0.01, 0.01))
            map.setRegion(region, animated: false)
        } else {
            locationMgr.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let l = locations.first {
            let region = MKCoordinateRegionMake(l.coordinate, MKCoordinateSpanMake(0.01, 0.01))
            map.setRegion(region, animated: false)
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
            map.removeFromSuperview()
            
            let vc = MapEditVC()
            vc.map = map
            map.userInteractionEnabled = true
            vc.showRadius = true
            NPSoftModalPresentationController.presentViewController(vc)
            vc.onHide = {
                let region = self.map.region
                self.map.removeFromSuperview()
                self.insertSubview(self.map, atIndex: 0)
                self.layoutIfNeeded()
                self.map.setRegion(region, animated: false)
                self.map.userInteractionEnabled = false
            }
        } else {
            let vc = MapEditVC()
            vc.map = MKMapView()
            vc.map.region = self.map.region
            vc.showShare = true
            vc.map.addAnnotation(CoordinateAnnotation(coord: self.map.centerCoordinate))
            NPSoftModalPresentationController.presentViewController(vc)
        }
        return true
    }
    
    let map = MKMapView()
    let pin = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        map.frame = insetBounds
        pin.center = bounds.center
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
                
                let activity = UIActivityViewController(activityItems: [mapItem], applicationActivities: nil)
                presentViewController(activity, animated: true, completion: nil)
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
    }
}
