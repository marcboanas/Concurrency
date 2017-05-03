//
//  MapViewController.swift
//  Concurrency
//
//  Created by Marc Boanas on 02/05/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    // MARK - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK - Properties
    
    let coreDataStack = CoreDataStack(modelName: "Model")
    
    var annotations: [MKPointAnnotation] = []
    var lastAnnotation: MKPointAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        
        // Long Press UIGestureRecogniver
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupMap() {
        
        let pins = CoreDataManager.sharedInstance().allPins
        for pin in pins {
            let annotation = MKPointAnnotation()
            let pinCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotation.coordinate = pinCoordinate
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
    }
    
    @objc private func addAnnotation(_ gestureRecognizer: UIGestureRecognizer) {

        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        switch gestureRecognizer.state {
        case .began:
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            lastAnnotation = annotation
            mapView.addAnnotation(annotation)
        case .changed:
            lastAnnotation.coordinate = newCoordinates
        case .ended:
            CoreDataManager.sharedInstance().addPin(coordinate: newCoordinates)
        default: break
        }
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = false
            pinView?.isDraggable = true
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
}

