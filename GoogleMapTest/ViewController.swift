//
//  ViewController.swift
//  GoogleMapTest
//
//  Created by Mohammad Fallah on 10/5/1397 AP.
//  Copyright © 1397 Mohammad Fallah. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    let locationManager = CLLocationManager()
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var pinImage: UIImageView!
    var des_tar = [CLLocationCoordinate2D]()
    @IBAction func pinClicked(_ sender: Any) {
        let a = mapView.camera.target
        print("\(a.latitude) : \(a.longitude)")
        let marker = GMSMarker(position: a)
        marker.map = mapView
        des_tar.append(a)
        if des_tar.count == 2 {
             fetchMapData()
            let coordinate0 =  CLLocation(latitude: des_tar[0].latitude, longitude: des_tar[0].longitude)
            let coordinate1 =  CLLocation(latitude: des_tar[1].latitude, longitude: des_tar[1].longitude)
            let distanceInMeters = coordinate0.distance(from: coordinate1)
            print("distance: " + String(describing: distanceInMeters))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
       
    }
    

    func fetchMapData() {
        
        let directionURL = "https://maps.googleapis.com/maps/api/directions/json?" +
            "origin=\(des_tar[0].latitude),\(des_tar[0].longitude)&destination=\(des_tar[1].latitude),\(des_tar[1].longitude)&" +
        "key=AIzaSyA3faFUCTuRD_coST53yukXAB8uFntuKEU"
        print(directionURL)
        
        
        Alamofire.request(directionURL).responseJSON
            { response in
                
                if let JSON = response.result.value {
                    
                    let mapResponse: [String: AnyObject] = JSON as! [String : AnyObject]
                    
                    let routesArray = (mapResponse["routes"] as? Array) ?? []
                    
                    let routes = (routesArray.first as? Dictionary<String, AnyObject>) ?? [:]
                    
                    let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String,AnyObject>) ?? [:]
                    let polypoints = (overviewPolyline["points"] as? String) ?? ""
                    let line  = polypoints
                    
                    self.addPolyLine(encodedString: line)
                }
        }
        
    }
    
    func addPolyLine(encodedString: String) {
        
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5
        polyline.strokeColor = .blue
        polyline.map = mapView
        
    }

    private func reverceGeocode (_ location : CLLocationCoordinate2D){
        let geoCoder = GMSGeocoder()
        geoCoder.reverseGeocodeCoordinate(location) {response,error in
            guard let address = response?.firstResult() , let lines = address.lines else {return}
            self.addressLabel.text = lines.joined(separator: "\n")
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
             self.addressLabel.isHidden = false
            let heightLabel = self.addressLabel.intrinsicContentSize.height
            self.mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: heightLabel, right: 0)
        }
    }

}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        manager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {return}
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing:0 , viewingAngle: 0)
        manager.stopUpdatingLocation()
    }
}
extension ViewController : GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverceGeocode(position.target)
    }
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.addressLabel.isHidden = true
    }
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print(coordinate.latitude)
    }
}
