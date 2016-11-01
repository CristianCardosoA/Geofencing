//
//  ViewController.swift
//  Example of Geotifications
//
//  Created by MacBook on 31/10/16.
//  Copyright © 2016 iTexico. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

var isCustomViewOpen = false

class ViewController: UIViewController{
    
    @IBOutlet var map: MKMapView!
    
    @IBAction func add(_ sender: AnyObject) {
        
    }
    
    func showLifeEventView(){
    
        let image : UIImage = UIImage(named:"grandma.jpg")!
        let customView = CustomViewController.initWithTitle(name: "Grandmother", bio : "Gwyneth Paltrow", image: image, frame: CGRect(x: 0, y: view.frame.size.height - (view.frame.size.height * 0.420) , width: self.view.frame.width, height: (view.frame.size.height * 0.420) ))
        
        if !isCustomViewOpen {
            isCustomViewOpen = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.view.addSubview(customView)
                self.view.layoutIfNeeded()
                }, completion: nil)
            
        }
        let tapGesture = UITapGestureRecognizer(target:self, action: #selector(ViewController.removeSubview))
        customView.addGestureRecognizer(tapGesture)
    }
    
    
    func removeSubview(){
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
            isCustomViewOpen = false
        }
    }
    
    @IBAction func currentLocation(_ sender: AnyObject) {
        map.zoomToUserLocation()
    }
    
    var geotifications: [Geotification] = []

    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        loadAllGeotifications()
                
        let uilongPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPress(gestureRecognizer:)))
        
        uilongPress.minimumPressDuration = 2
        
        map.addGestureRecognizer(uilongPress)
        
        map.delegate = self
        
    }
    
    func longPress(gestureRecognizer : UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            
            let touchPoint = gestureRecognizer.location(in: self.map)
            
            let newCoordinate = self.map.convert(touchPoint, toCoordinateFrom: self.map)
            
            let newYorkLocation = newCoordinate
            // Drop a pin
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = newYorkLocation
            self.map.addAnnotation(dropPin)
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        self.map.setRegion(region, animated: true)
        
    }
    
    func loadAllGeotifications() {
        
        geotifications = []
        
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        
        for savedItem in savedItems {
            guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
            add(geotification: geotification)
        }
    }
    
    func add(geotification: Geotification) {
        geotifications.append(geotification)
        map.addAnnotation(geotification)
        addRadiusOverlay(forGeotification: geotification)
    }
    
    func addRadiusOverlay(forGeotification geotification: Geotification) {
        map.add(MKCircle(center: geotification.coordinate, radius: geotification.radius))
    }
    
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
        
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        region.notifyOnEntry = true //ON ENTER PUSH NOTIFICATION
        return region
    }
    
    func startMonitoring(geotification: Geotification) {
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        let region = self.region(withGeotification: geotification)
        
        locationManager.startMonitoring(for: region)
    }
    
    func saveAllGeotifications() {
        
        var items: [Data] = []
        for geotification in geotifications {
            let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
}

// MARK: AddGeotificationViewControllerDelegate
extension ViewController: AddGeotificationsViewControllerDelegate {
    
    func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String) {
        controller.dismiss(animated: true, completion: nil)
        // 1
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note)
        add(geotification: geotification)
        // 2
        startMonitoring(geotification: geotification)
        saveAllGeotifications()
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        map.showsUserLocation = (status == .authorizedAlways)
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        showLifeEventView()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            //annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "point.png")
            let tapGesture = UITapGestureRecognizer(target:self, action: #selector(ViewController.removeSubview))
            annotationView.addGestureRecognizer(tapGesture)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

}

