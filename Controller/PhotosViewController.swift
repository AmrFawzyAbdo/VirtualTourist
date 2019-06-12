//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/17/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotosViewController:  UIViewController ,UICollectionViewDelegate, UICollectionViewDataSource,MKMapViewDelegate , NSFetchedResultsControllerDelegate{
    var dataController : DataController!
    var pin : Pin!
    var fetchedResultsController : NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    
    
    
    
    var saveObserverToken: Any?
    var itemsToDelete = Set<IndexPath>()
    
    var isEditMode = false
    var pinHasNoImagesLabel: UILabel?
    var totalImagesToFetch: Int = 0
    var imagesFetchedSoFar: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSaveNotificationObserver()
        
        let location = CLLocationCoordinate2D(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, 1000, 1000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.delegate = self
        
        addMapAnnotation(pin: pin!)
        flowLayout()
        collectionView.reloadData()
        
        updateControls(editing: isEditMode)
        
        if(self.pinHasNoImagesLabel == nil)
        {
            self.pinHasNoImagesLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:25))
            self.pinHasNoImagesLabel!.text = "No images for this place"
            self.pinHasNoImagesLabel!.textColor = UIColor.red
            self.pinHasNoImagesLabel!.center = CGPoint(x: self.view.frame.width / 2, y: 200)
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        flowLayout()
        collectionView.reloadData()
        if(fetchedResultsController.fetchedObjects!.count == 0)
        {
            startNewDownload()
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        setFlowLayoutParams()
        collectionView.reloadData()
    }
    
    
    func setupFetchedResultsController()
    {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "downloadDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch
        {
            fatalError(error.localizedDescription)
        }
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return min(Constants.maxImagesPerAlbum, fetchedResultsController.fetchedObjects?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell (withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.black.cgColor
        
        let photoObjectID = fetchedResultsController.object(at: indexPath).objectID
        var photo = dataController.backgroundContext.object(with: photoObjectID) as! Photo
        if(photo.file != nil)
        {
            cell.imageView.image = UIImage(data: photo.file!)
        }
        else
        {
            cell.imageView.image = UIImage(named: "VirtualTourist_180")
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            cell.addSubview(activityIndicator)
            activityIndicator.center = CGPoint(x: cell.bounds.size.width/2, y: cell.bounds.size.height/2)
            activityIndicator.color = UIColor.black
            activityIndicator.startAnimating()
            
            Client.sharedInstance().getImageFromUrl(urlString: photo.url!)
            {
                (_ success: Bool, _ imagePath: String?, _ imageData: Data?, _ errorString: String?)->Void in
                
                var allDone = false
                
                if(success)
                {
                    DispatchQueue.main.async
                        {
                            
                            self.imagesFetchedSoFar = self.imagesFetchedSoFar + 1
                            if(self.imagesFetchedSoFar == self.totalImagesToFetch)
                            {
                                allDone = true
                                
                                if(allDone)
                                {
                                    self.newCollection.isEnabled = true
                                    activityIndicator.stopAnimating()
                                    activityIndicator.removeFromSuperview()
                                }
                            }
                    }
                    
                    self.dataController.backgroundContext.perform
                        {
                            photo = self.dataController.backgroundContext.object(with: photoObjectID) as! Photo
                            photo.file = imageData
                            try? self.dataController.backgroundContext.save()
                    }
                }
                else
                {
                    print("Error downloading image")
                }
                
            }
        }
        
        if(itemsToDelete.contains(indexPath))
        {
            cell.alpha = 0.5
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if(itemsToDelete.contains(indexPath))
        {
            itemsToDelete.remove(indexPath)
        }
        else
        {
            itemsToDelete.insert(indexPath)
        }
        
        isEditMode = itemsToDelete.count > 0
        updateControls(editing: isEditMode)
        
        collectionView.reloadData()
    }
    
    
    func setFlowLayoutParams()
    {
        let horizontalSpacing = 0
        let verticalSpacing = 2
        let numItems = 3
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: (width / CGFloat(numItems)) - CGFloat(numItems - horizontalSpacing), height: (width / CGFloat(numItems)) -  CGFloat(numItems - horizontalSpacing))
        layout.minimumInteritemSpacing = CGFloat(horizontalSpacing)
        layout.minimumLineSpacing = CGFloat(verticalSpacing)
    }
    
    
    @IBAction func newCollection(_ sender: Any) {
        if(isEditMode)
        {
            for item in itemsToDelete
            {
                let objectID = fetchedResultsController.object(at: item).objectID
                dataController.backgroundContext.perform
                    {
                        let photoToDelete = self.dataController.backgroundContext.object(with: objectID)
                        self.dataController.backgroundContext.delete(photoToDelete)
                }
            }
            itemsToDelete.removeAll()
            dataController.backgroundContext.perform
                {
                    try? self.dataController.backgroundContext.save()
            }
        }
        else
        {
            if((fetchedResultsController.fetchedObjects?.count)! > 0)
            {
                let photos = fetchedResultsController.fetchedObjects
                var objectIDs = [NSManagedObjectID]()
                for photo in photos!
                {
                    objectIDs.append(photo.objectID)
                }
                
                dataController.backgroundContext.perform
                    {
                        for objectID in objectIDs
                        {
                            let photoToDelete = self.dataController.backgroundContext.object(with: objectID)
                            self.dataController.backgroundContext.delete(photoToDelete)
                        }
                        
                        try? self.dataController.backgroundContext.save()
                }
                
                startNewDownload()
            }
        }
    }
    
    deinit
    {
        removeSaveNotificationObserver()
    }
    
    
    
    func startNewDownload()
    {
        newCollection.isEnabled = false
        totalImagesToFetch = Constants.maxImagesPerAlbum
        imagesFetchedSoFar = 0
        
        DispatchQueue.main.async
            {
                self.pinHasNoImagesLabel?.removeFromSuperview()
        }
        
        let pinID = pin.objectID
        Client.sharedInstance().getPhotos(latitude: pin!.latitude, longitude: pin?.longitude)
        {
            (_ success: Bool, _ totalImages: Int, _ pages: Int, _ perPage: Int, _ errorString: String?)->Void in
            
            if(success)
            {
                if(totalImages > 0)
                {
                    Client.sharedInstance().getRandomPhotos(latitude: self.pin!.latitude, longitude: self.pin?.longitude, totalImages: totalImages, totalPages: pages, perPage: perPage, maxPhotos: Constants.maxImagesPerAlbum)
                    {
                        (_ success: Bool, _ imageURLs: [String], _ errorString: String?)->Void in
                        
                        if(success)
                        {
                            self.totalImagesToFetch = imageURLs.count
                            self.imagesFetchedSoFar = 0
                            
                            self.dataController.backgroundContext.perform
                                {
                                    for url in imageURLs
                                    {
                                        let photo = Photo(context: self.dataController.backgroundContext)
                                        photo.downloadDate = Date()
                                        photo.url = url
                                        photo.file = nil
                                        photo.pin = self.dataController.backgroundContext.object(with: pinID) as? Pin
                                    }
                                    try? self.dataController.backgroundContext.save()
                            }
                            
                            DispatchQueue.main.async
                                {
                                    self.collectionView.reloadData()
                            }
                        }
                        else
                        {
                            DispatchQueue.main.async
                                {
                                    self.showError(message: errorString!)
                            }
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.async
                        {
                            self.view.addSubview(self.pinHasNoImagesLabel!)
                            self.newCollection.isEnabled = false
                    }
                }
            }
            else
            {
                DispatchQueue.main.async
                    {
                        self.showError(message: errorString!)
                }
            }
        }
    }
    
    
    
    func addSaveNotificationObserver()
    {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController?.viewContext, queue: nil, using: handleSaveNotification(notification:))
    }
    
    func removeSaveNotificationObserver()
    {
        if let token = saveObserverToken
        {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    func handleSaveNotification(notification:Notification)
    {
        DispatchQueue.main.async
            {
                self.updateCollectionView()
        }
    }
    
    fileprivate func updateCollectionView()
    {
        collectionView.reloadData()
    }
    
    
    func addMapAnnotation(pin: Pin)
    {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.addAnnotation(annotation)
    }
    
    func flowLayout()
    {
        let horizontalSpacing = 0
        let verticalSpacing = 2
        let numItems = 3
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: (width / CGFloat(numItems)) - CGFloat(numItems - horizontalSpacing), height: (width / CGFloat(numItems)) -  CGFloat(numItems - horizontalSpacing))
        layout.minimumInteritemSpacing = CGFloat(horizontalSpacing)
        layout.minimumLineSpacing = CGFloat(verticalSpacing)
    }
    
    func updateControls(editing: Bool)
    {
        if(editing)
        {
            newCollection.title = "Remove Selected Pictures"
        }
        else
        {
            newCollection.title = "New Collection"
        }
    }
    
    
    
    func showError(message: String)
    {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            print("Insert")
            break
            
        case .delete:
            print("Delete")
            DispatchQueue.main.async
                {
                    self.isEditMode = self.itemsToDelete.count > 0
                    self.updateControls(editing: self.isEditMode)
                    self.collectionView.reloadData()
            }
            break
            
        case .update:
            print("Update Operation")
            DispatchQueue.main.async
                {
                    self.collectionView.reloadData()
            }
            break
            
        case .move:
            print("Move Operation")
            break
        }
    }
    
}
