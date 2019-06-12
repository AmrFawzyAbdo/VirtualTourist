//
//  TravelMapViewController.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/17/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelMapViewController: UIViewController , MKMapViewDelegate , NSFetchedResultsControllerDelegate {
    var dataController : DataController!
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    var isEditMode = false
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    
    func setupFetchedResultsController(){
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch  {
            fatalError(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupFetchedResultsController()
        
        for item in fetchedResultsController.fetchedObjects! {
            addMapAnnotation(pin: item)
        }
        isEditMode = false
        updateControls(editing: isEditMode)
        
    }
    
    func addMapAnnotation(pin  :Pin){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude , longitude: pin.longitude)
        mapView.addAnnotation(annotation)
    }
    
    
    func deleteMapAnnotation(pin: Pin)
    {
        for annotation in mapView.annotations
        {
            if(annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude)
            {
                mapView.removeAnnotation(annotation)
                break
            }
        }
    }
    
    
    func updateControls(editing: Bool)
    {
        if(editing)
        {
            toolbar.isHidden = false
            editButton.title = "Done"
        }
        else
        {
            toolbar.isHidden = true
            editButton.title = "Edit"
        }
        editButton.isEnabled = isEditMode || ((!isEditMode) && mapView.annotations.count > 0)
    }
    
    
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        if(!isEditMode)
        {
            if(sender.state == .began)
            {
                let touchPoint = sender.location(in: mapView)
                let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                addPin(lat: newCoordinates.latitude, lon: newCoordinates.longitude)
                updateControls(editing: isEditMode)
            }
        }
    }
    
    func addPin(lat : CLLocationDegrees , lon : CLLocationDegrees){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = lat
        pin.longitude = lon
        try? dataController.viewContext.save()
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "TouristLocationPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .red
        }
        else
        {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        mapView.deselectAnnotation(view.annotation!, animated: true)
        if(isEditMode)
        {
            deletePin(for: view.annotation!)
            updateControls(editing: isEditMode)
        }
        else
        {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "collectionViewController") as! PhotosViewController
            
            controller.dataController = dataController
            controller.pin = getPin(for: view.annotation!)
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func deletePin(for annotation: MKAnnotation)
    {
        let pinToDelete: Pin? = getPin(for: annotation)
        
        if(pinToDelete != nil)
        {
            dataController.viewContext.delete(pinToDelete!)
            try? dataController.viewContext.save()
        }
    }
    
    func getPin(for annotation: MKAnnotation)->Pin?
    {
        var pin: Pin?
        
        for item in fetchedResultsController.fetchedObjects!
        {
            if(item.latitude == annotation.coordinate.latitude && item.longitude == annotation.coordinate.longitude)
            {
                pin = item
                
                break
            }
        }
        
        return pin
    }
    
    
    
    @IBAction func editPress(_ sender: Any) {
        isEditMode = !isEditMode
        updateControls(editing: isEditMode)
    }
    
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            let pin = anObject as! Pin
            addMapAnnotation(pin: pin)
            break
        case .delete:
            let pin = anObject as! Pin
            deleteMapAnnotation(pin: pin)
            break
        case .update:
            break
        case .move:
            break
        }
    }
    
}
