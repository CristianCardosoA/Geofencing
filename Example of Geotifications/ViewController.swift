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
import CoreData

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

var isCustomViewOpen = false

class ViewController: UIViewController{
    
    var delegateAddGeotification: AddGeotificationsViewControllerDelegate?
    
    var geotifications: [Geotification] = []
    
    var locationManager = CLLocationManager()
    
    var context : NSManagedObjectContext? = nil
    
    
    @IBOutlet var map: MKMapView!
    
    
    @IBAction func add(_ sender: AnyObject) {
        showAlertWithInput(withTitle: "Add a geotification", message: "", delegate:  delegateAddGeotification)
    }
    
    
    @IBAction func currentLocation(_ sender: AnyObject) {
        map.zoomToUserLocation()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        context = appDelegate.persistentContainer.viewContext

        delegateAddGeotification = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        loadAllGeotifications()
        
        /*
                
        let uilongPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPress(gestureRecognizer:)))
        
        uilongPress.minimumPressDuration = 1
        
        map.addGestureRecognizer(uilongPress)
 
         */
        
        map.delegate = self
    }
    
    func showLifeEventView(anotation : MKAnnotation){
        
        let image : UIImage = UIImage(named:"grandma.jpg")!
        let customView = CustomViewController.initWithGeotification(name: (anotation as! Geotification).note, bio : String((anotation as! Geotification).coordinate.latitude), image: image, frame: CGRect(x: 0, y: view.frame.size.height - (view.frame.size.height * 0.420) , width: self.view.frame.width, height: (view.frame.size.height * 0.420) ))
        
        if !isCustomViewOpen {
            isCustomViewOpen = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.view.addSubview(customView)
                self.view.layoutIfNeeded()
                }, completion: nil)
            
        }
        let tapGesture = CustomTapGestureRecognizer(target:self, action: #selector(ViewController.removeSubview(customTap:)))
    
        if let annotationView = map.view(for: anotation){
            
            tapGesture.anotationView = annotationView
            tapGesture.anotationView?.image = UIImage(named: "focus.png")
            customView.addGestureRecognizer(tapGesture)

        }else{
         print("null view")
        }
    }
    
    func removeSubview( anotation : MKAnnotation){
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
            isCustomViewOpen = false
            for annotation in map.annotations {
                let viewI = map.view(for: annotation)
                
                if annotation.isMember(of: Geotification.self) &&  annotation.isEqual(anotation){
                    if annotation .isMember(of: Geotification.self) {
                        viewI?.image = UIImage(named: "point.png")
                    }
                }
            }
        }
    }
    
    func removeSubview(customTap : CustomTapGestureRecognizer){
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
            isCustomViewOpen = false
            let view = customTap.anotationView
            view?.image = UIImage(named: "point.png")
        }
    }

    
   /* func longPress(gestureRecognizer : UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            
            let touchPoint = gestureRecognizer.location(in: self.map)
            
            let newCoordinate = self.map.convert(touchPoint, toCoordinateFrom: self.map)
            
            let dropPin = MKPointAnnotation()
            
            dropPin.coordinate = newCoordinate
            
            self.map.addAnnotation(dropPin)
        }
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        self.map.setRegion(region, animated: true)
        
    }
    
    func loadAllGeotifications() {
        
        geotifications = []
        
        /*guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        
        for savedItem in savedItems {
            guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
            add(geotification: geotification)
        }*/
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName : "Geotification")
        request.returnsObjectsAsFaults = false
        
        do{
            
            let results = try context?.fetch(request)
            
            if (results?.count)! > 0 {
                
                for result in results as! [NSManagedObject]{
                    
                    let latitude = result.value(forKey: "latitude") as? Double
                    let longitude = result.value(forKey: "longitude") as? Double
                    _ = result.value(forKey: "title") as? String
                    _ = result.value(forKey: "subtitle") as? String
                    let radius = result.value(forKey: "radius") as? Double
                    let note = result.value(forKey: "note") as? String
                    let identifier = result.value(forKey: "identifier") as? String
                    
                    add(geotification: Geotification(coordinate: CLLocationCoordinate2DMake(latitude!, longitude!), radius: radius!, identifier: identifier!, note: note!))
                }
                
            } else{
                print("No results")
            }
            
        } catch {
            print("Couldnt fetch results")
            
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
        
        //var items: [Data] = []
        for geotification in geotifications {
            //let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
            //items.append(item)
            let newGeotification = NSEntityDescription.insertNewObject(forEntityName: "Geotification", into: self.context!)
            
            newGeotification.setValue(geotification.coordinate.latitude, forKey: "latitude")
            newGeotification.setValue(geotification.coordinate.longitude, forKey: "longitude")
            newGeotification.setValue(geotification.title, forKey: "title")
            newGeotification.setValue(geotification.note, forKey: "note")
            newGeotification.setValue(geotification.subtitle, forKey: "subtitle")
            newGeotification.setValue(geotification.radius, forKey: "radius")
            newGeotification.setValue(geotification.identifier, forKey: "identifier")
            
            do{
                try context?.save()
                print("Saved")
                
            } catch {
                print("Was an error")
            }

        }
        
        //UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: AddGeotificationsViewControllerDelegate {
    
    func addGeotificationViewController(didAddCoordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String){

        
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geotification(coordinate: didAddCoordinate, radius: clampedRadius, identifier: identifier, note: note)
        
        showAlert(withTitle: "Geotification Added", message: note)
        
        add(geotification: geotification)
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
        
        let selectedAnnotation = view.annotation
        
            for annotation in mapView.annotations {
                let viewI = mapView.view(for: annotation)

                if !(viewI?.annotation is MKUserLocation){
                    if annotation.isEqual(selectedAnnotation) {
                        showLifeEventView(anotation: annotation)
                    }else{
                        viewI?.image = UIImage(named: "point.png")
                    }
                }
            }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
       /* var annotationView: MKAnnotationView?
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
            let tapGesture = CustomTapGestureRecognizer(target:self, action: #selector(ViewController.removeSubview(customTap:)))
            tapGesture.anotationView = annotationView
            annotationView.addGestureRecognizer(tapGesture)
        }*/
        
        if annotation is Geotification {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKAnnotationView(annotation:annotation, reuseIdentifier:annotationIdentifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "point.png")
                let tapGesture = CustomTapGestureRecognizer(target:self, action: #selector(ViewController.removeSubview(customTap:)))
                tapGesture.anotationView = annotationView
                annotationView.addGestureRecognizer(tapGesture)

                return annotationView
            }
            
        }
        return nil

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
