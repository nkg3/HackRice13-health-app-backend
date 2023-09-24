//
//  GetLocation.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/23/23.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var location: CLLocation? // Publish the location as an observable object

    override init() {
        super.init()
        setupLocationManager()
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Set desired accuracy
        locationManager.requestWhenInUseAuthorization() // Request location access when the app is in use
        locationManager.startUpdatingLocation() // Start updating the location
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location // Update the published location
        }
    }
}

