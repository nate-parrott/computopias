//
//  CheckinViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class Checkin {
    var text = ""
    var lat: Double = 0
    var lon: Double = 0
    var venueID: String?
    
    func toJson() -> [String: AnyObject] {
        return ["text": text, "lat": lat, "lon": lon, "venueID": venueID ?? NSNull()]
    }
    
    func importJson(j: [String: AnyObject]) {
        text = j["text"] as? String ?? ""
        lat = j["lat"] as? Double ?? 0
        lon = j["lon"] as? Double ?? 0
        venueID = j["venueID"] as? String
    }
}

class CheckinViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    // MARK: API
    var checkin = Checkin() {
        didSet {
            _updateUI()
        }
    }
    var editable = true {
        didSet {
            _updateUI()
        }
    }
    var onCheckinUpdated: (() -> ())?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        _updateUI()
        centerPin.layer.cornerRadius = centerPin.bounds.size.height/2
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let c = onCheckinUpdated { c() }
    }
    
    // MARK UI
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var locationTitle: UITextField!
    @IBOutlet var centerPin: UIView!
    var geocodedLocations = [(CLLocationCoordinate2D, String)]()
    
    @IBAction func pickDifferentVenue() {
        
    }
    
    func _updateUI() {
        let coord = CLLocationCoordinate2DMake(checkin.lat, checkin.lon)
        CheckinViewController.moveMap(map, toPoint: coord)
        _updateUIBesidesMap()
        if editable {
            coordinateAnnotation = CoordinateAnnotation(coord: coord)
        } else {
            coordinateAnnotation = nil
        }
    }
    
    func _updateUIBesidesMap() {
        locationTitle.text = checkin.text
        centerPin.hidden = !editable
        locationTitle.userInteractionEnabled = editable
    }
    
    var _mapUpdateTimer: NSTimer?
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if editable {
            _mapUpdateTimer?.invalidate()
            _mapUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(CheckinViewController.updateGeolocation), userInfo: nil, repeats: false)
            checkin.text = ""
            checkin.venueID = nil
            geocodedLocations = []
            _updateUIBesidesMap()
        }
    }
    
    func updateGeolocation() {
        let g = CLGeocoder()
        let coord = map.centerCoordinate
        g.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { (let placemarksOpt, _) in
            if let p = placemarksOpt where coord.latitude == self.map.centerCoordinate.latitude && coord.longitude == map.centerCoordinate.longitude {
                var pairs = [(CLLocationCoordinate2D, String)]()
                for placemark in p {
                    if let loc = placemark.location, let name = placemark.name {
                        pairs += [(loc.coordinate, name)]
                    }
                }
                self.geocodedLocations = pairs
                self.checkin.text = pairs.first?.1 ?? ""
            }
        }
    }
    
    class func moveMap(map: MKMapView, toPoint: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMake(toPoint, MKCoordinateSpanMake(0.01, 0.01))
        map.setRegion(region, animated: false)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectAll(nil)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text ?? "" as NSString).stringByReplacingCharactersInRange(range, withString: string)
        checkin.text = text
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Marked position
    class CoordinateAnnotation: NSObject, MKAnnotation {
        init(coord: CLLocationCoordinate2D) {
            coordinate = coord
        }
        var coordinate: CLLocationCoordinate2D
    }
    var coordinateAnnotation: CoordinateAnnotation? {
        didSet {
            if let o = oldValue {
                map.removeAnnotation(o)
            }
            if let a = coordinateAnnotation {
                map.addAnnotation(a)
            }
        }
    }
    
    // MARK: User location
    @IBAction func zoomToCurrentLocation() {
        _locate()
    }
    let locationMgr = CLLocationManager()
    func _locate() {
        locationMgr.delegate = self
        locationMgr.requestWhenInUseAuthorization()
        if let loc = locationMgr.location {
            checkin.lat = loc.coordinate.latitude
            checkin.lon = loc.coordinate.longitude
            checkin.geolocate()
            _updateUI()
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
}
