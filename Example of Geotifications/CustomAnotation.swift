//
//  CustomAnotation.swift
//  Example of Geotifications
//
//  Created by MacBook on 01/11/16.
//  Copyright © 2016 iTexico. All rights reserved.
//

import MapKit

class CustomAnotation: NSObject, MKAnnotation {
    
        let title: String?
        let locationName: String
        let discipline: String
        let coordinate: CLLocationCoordinate2D

        init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
            self.title = title
            self.locationName = locationName
            self.discipline = discipline
            self.coordinate = coordinate
            
            super.init()
        }
        
        var subtitle: String? {
            return locationName
        }
}
