//
//  ViewController.swift
//  SafetyRoute
//
//  Created by Namratha Prithviraj on 10/26/19.
//  Copyright © 2019 Namratha Prithviraj. All rights reserved.
//

/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import GoogleMaps
import GooglePlaces
import MessageUI

class MapViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
   
    var path: GMSPath?
    
    // Update the map once the user has made their selection.
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        // Clear the map.
        mapView.clear()
        
        // Add a marker to the map.
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
        }
        
        listLikelyPlaces()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        listLikelyPlaces()
        
        
        let marker = GMSMarker()
        //marker.position = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)
        marker.position = CLLocationCoordinate2D(latitude: 37.870397, longitude: -122.252419)
        marker.title = "Start"
        //marker.snippet = "Malaysia"
        marker.map = mapView
        
        let marker2 = GMSMarker()
        marker2.position = CLLocationCoordinate2D(latitude: 37.871629, longitude: -122.252707)
        marker2.title = "End"
        //marker2.snippet = "Malaysia"
        marker2.map = mapView
 
        
     /*  let a_coordinate_string = "37.872167, -122.263386"
        let b_coordinate_string = "37.875176, -122.256642"
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(a_coordinate_string)&destination=\(b_coordinate_string)&mode=walking&key=AIzaSyDoagRoGRHcoory1pmwdyl03rh3xIQLFJI"
        
        
        guard let url = URL(string: urlString) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            do {
                guard let data = data else {
                    throw JSONError.NoData
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                    throw JSONError.ConversionFailed
                }
                print(json)
            } catch let error as JSONError {
                print(error.rawValue)
            } catch let error as NSError {
                print(error.debugDescription)
            }
            
        })
        task.resume()
        

        let path = GMSPath(fromEncodedPath: "yjxP{}mkRbCr@hI|CjCp@hB^vAFnABzBG`C[ZGFXLx@wBb@_@Da@@iA@SHOZ?n@D\\J\\NTRRZRf@R")
        let polyline = GMSPolyline(path:path)
        polyline.strokeWidth = 4
       // polyline.strokeColor = UIColor.init(hue: 210, saturation: 88, brightness: 84, alpha: 1)
        polyline.map = mapView
        */
        
        fetchRoute(from: marker.position, to: marker2.position)
   

    }
    
    
    
    func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        
        let combinedUrl : String = "https://maps.googleapis.com/maps/api/directions/json?origin=37.870397,-122.252419&destination=37.871629,-122.252707&mode=walking&key=AIzaSyDoagRoGRHcoory1pmwdyl03rh3xIQLFJI"
        
        let url = URL(string:combinedUrl)
        
        let task = URLSession.shared.dataTask(with: url!) { (data:Data?, response:URLResponse?, error:Error?) in
            
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
                print(json)
                //We need to get to the points key in overview_polyline object in order to pass the points to GMSPath.
                let route = (((json.object(forKey: "routes") as! NSArray).object(at: 0) as! NSDictionary).object(forKey: "overview_polyline") as! NSDictionary).value(forKey: "points") as! String
                
                //Draw on main thread always else it will crash
                DispatchQueue.main.async {
                    self.path  = GMSPath(fromEncodedPath:route)!
                    let polyline  = GMSPolyline(path: self.path)
                    polyline.strokeColor = UIColor.green
                    polyline.strokeWidth = 5.0
                    
                    //mapView is your GoogleMaps Object i.e. _mapView in your case
                    polyline.map = self.mapView
                }
            } catch {
            }
        }
        task.resume()
        
        let updateTimer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(MapViewController.checkLocation), userInfo: nil, repeats: true)
        
        print(updateTimer)
    }
    
    @objc func checkLocation() {
        let onPath = GMSGeometryIsLocationOnPathTolerance(locationManager.location!.coordinate, path!, true, 20)
        if (onPath == false){
            displayMessageInterface()
        }
    }
//
//    func GMSGeometryIsLocationOnPathTolerance(point: CLLocationCoordinate2D, path: GMSPath, geodesic: Bool, tolerance: CLLocationDistance){
//        print("Made it")
//    }
    

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
    }
    
    func displayMessageInterface() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.recipients = ["4088589750"]
        composeVC.body = "SOS"
        
        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
        } else {
            print("Can't send messages.")
        }
    }
    
    
    enum JSONError: String, Error {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    
    // Populate the array with the list of likely places.
    func listLikelyPlaces() {
        // Clean up from previous sessions.
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            if let error = error {
                // TODO: Handle the error.
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            
            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        })
    }
    
    // Prepare the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSelect" {
            if let nextViewController = segue.destination as? PlacesViewController {
                nextViewController.likelyPlaces = likelyPlaces
            }
        }
    }
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        listLikelyPlaces()
        
       
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    
    
   
   
}
