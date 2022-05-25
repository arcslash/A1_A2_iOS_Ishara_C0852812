//
//  ViewController.swift
//  Map Demo
//
//  Created by Mohammad Kiani on 2021-01-21.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnDirection: UIButton!
    
    // create location manager
    var locationMnager = CLLocationManager()
    
    // destination variable
    var destination: CLLocationCoordinate2D!
    
    // create the places array
    let places = Place.getPlaces()
    
    var triangleAnnotations: [MKAnnotation] = []
    
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    let THRESHOLD_DISTANCE = 100.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.isZoomEnabled = false
        mapView.showsUserLocation = true
        
        btnDirection.isHidden = true
        
        // we assign the delegate property of the location manager to be this class
        locationMnager.delegate = self
        
        // we define the accuracy of the location
        locationMnager.desiredAccuracy = kCLLocationAccuracyBest
        
        // rquest for the permission to access the location
        locationMnager.requestWhenInUseAuthorization()
        
        // start updating the location
        locationMnager.startUpdatingLocation()
        
        // 1st step is to define latitude and longitude
        
        
        // 2nd step is to display the marker on the map
//        displayLocation(latitude: latitude, longitude: longitude, title: "Toronto City", subtitle: "You are here")
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(addLongPressAnnotattion))
        mapView.addGestureRecognizer(uilpgr)
        
        // add double tap
        addDoubleTap()
        
        // giving the delegate of MKMapViewDelegate to this class
        mapView.delegate = self
        
        // add annotations for the places
//        addAnnotationsForPlaces()
        
        // add polyline
//        addPolyline()
        
        // add polygon
//        addPolygon()
        
        
    }
    
    
    
    func isCloseToPoint(p1: CLLocation, p2: CLLocation ) -> Bool{
        let distance = p1.distance(from: p2)
        print("distance:", String(distance))
        if (abs(distance) > THRESHOLD_DISTANCE ){
            return false
        }
        return true
        
    }
    
    
    //MARK: - draw route between two places
    @IBAction func drawRoute(_ sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        
        let sourcePlaceMark = MKPlacemark(coordinate: locationMnager.location!.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        // request a direction
        let directionRequest = MKDirections.Request()
        
        // assign the source and destination properties of the request
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        // transportation type
        directionRequest.transportType = .automobile
        
        // calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            // create the route
            let route = directionResponse.routes[0]
            // drawing a polyline
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            // define the bounding map rect
            let rect = route.polyline.boundingMapRect
            self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            
//            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        removePin()
//        print(locations.count)
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        currentLocation.latitude = latitude
        currentLocation.longitude = longitude
        displayLocation(latitude: latitude, longitude: longitude, title: "my location", subtitle: "you are here")
    }
    

    func addAnnotationsForPlaces() {
        mapView.addAnnotations(places)
        
        let overlays = places.map {MKCircle(center: $0.coordinate, radius: 2000)}
        mapView.addOverlays(overlays)
    }
    
   
    func addPolyline() {
        let coordinates = places.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }
    
    func addTriangle(){
        var coordinates: [CLLocationCoordinate2D] = []
        for annotation in triangleAnnotations{
            coordinates.append(annotation.coordinate)
            
        }
        let triangle = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        
        
        mapView.addOverlay(triangle)
        mapView.addOverlay(polygon)
        
    }
    

    func addPolygon() {
        let coordinates = places.map {$0.coordinate}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }
    
   
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
        
    }
    
    func reDrawAnnotations(){
        let labels = ["A", "B", "C"]
        for (index, pointAnot) in triangleAnnotations.enumerated(){
            let annotation = MKPointAnnotation()
            annotation.title = labels[index]
            let p1 = CLLocation(latitude: pointAnot.coordinate.latitude, longitude: pointAnot.coordinate.longitude)
            let p2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = p2.distance(from: p1)
            annotation.coordinate = pointAnot.coordinate
            annotation.subtitle = pointAnot.subtitle as! String
            mapView.addAnnotation(annotation)
        }
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        //removePin()
        
        // add annotation
        let touchPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        
        if(triangleAnnotations.count == 0){
            annotation.title = "A"
            let p1 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let p2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = p2.distance(from: p1)
            annotation.subtitle = "Point is " + String(distance) + " far away from you"
            annotation.coordinate = coordinate
            triangleAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
            
        }else if(triangleAnnotations.count == 1){
            annotation.title = "B"
            let p1 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let p2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = p2.distance(from: p1)
            annotation.subtitle = "Point is " + String(distance) + " far away from you"
            annotation.coordinate = coordinate
            triangleAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
        }else if(triangleAnnotations.count == 2){
            annotation.title = "C"
            let p1 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let p2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = p2.distance(from: p1)
            annotation.subtitle = "Point is " + String(distance) + " far away from you"
            annotation.coordinate = coordinate
            triangleAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
            addTriangle()
            triangleAnnotations.append(annotation)
        }else{
            if(isCloseToPoint(p1: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), p2: CLLocation(
                latitude: triangleAnnotations[0].coordinate.latitude,
                longitude:triangleAnnotations[0].coordinate.longitude))){
                print("Remove A")
                triangleAnnotations.remove(at: 0)
                mapView.removeOverlays(mapView.overlays)
                reDrawAnnotations()
                
            }else if(isCloseToPoint(p1: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), p2: CLLocation(
                latitude: triangleAnnotations[1].coordinate.latitude,
                longitude:triangleAnnotations[1].coordinate.longitude))){
                print("Remove B")
                triangleAnnotations.remove(at: 1)
                mapView.removeOverlays(mapView.overlays)
                reDrawAnnotations()
                        
                }else if(isCloseToPoint(p1: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), p2: CLLocation(
                    latitude: triangleAnnotations[2].coordinate.latitude,
                    longitude:triangleAnnotations[2].coordinate.longitude))){
                    print("Remove C")
                    triangleAnnotations.remove(at: 2)
                    mapView.removeOverlays(mapView.overlays)
                    reDrawAnnotations()
                    
                }else{
                    removeTriangleAnnotations()
                    print("Remove All")
                    annotation.title = "A"
                    let p1 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                    let p2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                    let distance = p2.distance(from: p1)
                    annotation.subtitle = "Point is " + String(distance) + " far away from you"
                    annotation.coordinate = coordinate
                    triangleAnnotations.append(annotation)
                    mapView.addAnnotation(annotation)
                }
                
            }
        destination = coordinate
        btnDirection.isHidden = false
        }
        
        

        
        
    
    //MARK: - long press gesture recognizer for the annotation
    @objc func addLongPressAnnotattion(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        // add annotation for the coordinatet
        let annotation = MKPointAnnotation()
        annotation.title = "my favorite"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    

    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        

    }
    
    
    func removeTriangleAnnotations() {
        for annotation in triangleAnnotations {
            mapView.removeAnnotation(annotation)
        }
        triangleAnnotations = []
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)

    }
    
    

    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String,
                         subtitle: String) {
        // 2nd step - define span
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        // 3rd step is to define the location
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // 4th step is to define the region
        let region = MKCoordinateRegion(center: location, span: span)
        
        // 5th step is to set the region for the map
        mapView.setRegion(region, animated: true)
        
        // 6th step is to define annotation
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = location
        mapView.addAnnotation(annotation)
    }

}

extension ViewController: MKMapViewDelegate {
    
    //MARK: - viewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        switch annotation.title {
        case "my location":
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.markerTintColor = UIColor.blue
            return annotationView
        case "my destination":
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            annotationView.pinTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            return annotationView
        case "my favorite":
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        case "A":
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        case "B":
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        case "C":
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        default:
            return nil
        }
    }
    
    //MARK: - callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let alertController = UIAlertController(title: "Your Favorite", message: "A nice place to visit", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - rendrer for overlay func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let rendrer = MKCircleRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.black.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        } else if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 3
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.yellow
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

