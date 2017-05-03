//
//  CoreDataManager.swift
//  Concurrency
//
//  Created by Marc Boanas on 03/05/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import CoreData
import CoreLocation

class CoreDataManager: NSObject {
    
    let coreDataStack = CoreDataStack(modelName: "Model")
    
    var allPins: [Pin] = []
    
    override init() {
        super.init()
        getAllPins()
    }
    
    func getAllPins() {
        
        let fetchedResultsController: NSFetchedResultsController<Pin> = {
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack.managedObjectContext , sectionNameKeyPath: nil, cacheName: nil)
            return fetchedResultController
        }()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching pins")
        }
        
        let pins = fetchedResultsController.fetchedObjects!
        
        for pin in pins {
            allPins.append(pin)
        }
        
    }
    
    func addPin(coordinate: CLLocationCoordinate2D!) {
        
        let newPrivateQueueContext = coreDataStack.privateManagedObjectContext
        
        newPrivateQueueContext.perform {
            let pin = Pin(context: newPrivateQueueContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            self.coreDataStack.saveChanges()
            self.allPins.append(pin)
            let pinObjectID = pin.objectID
            self.loadPhotosFromFlickr(pinObjectID)
        }
        
    }
    
    private func loadPhotosFromFlickr(_ pinObjectID: NSManagedObjectID) {

        let privateContext = coreDataStack.privateManagedObjectContext

        if let pin = privateContext.object(with: pinObjectID) as? Pin {
        
            FlickrClient.sharedInstace().getPhotosByLatAndLong(latitude: pin.latitude, longitude: pin.longitude, pages: "\(pin.pages)") { (photosDictionary, errorString) in
                
                guard errorString == nil else {
                    print(errorString!)
                    return
                }
                
                guard let photosDictionary = photosDictionary else {
                    print("No photo dictionary returned from Flickr")
                    return
                }
                
                self.addPhotosForPin(photosDictionary: photosDictionary, pinObjectID: pin.objectID)
                self.downloadPhotosForPin(pinObjectID: pin.objectID)
            }
        }
    }
    
    private func addPhotosForPin(photosDictionary: [String: AnyObject], pinObjectID: NSManagedObjectID) {
        
        let privateContext = coreDataStack.privateManagedObjectContext
        
        privateContext.perform {
        
            if let pin = privateContext.object(with: pinObjectID) as? Pin {
                
                if let pages = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Pages] {
                    pin.pages = pages as! Int
                    self.coreDataStack.saveChanges()
                } else {
                    print("Error saving pages")
                }
                
                if let photoArray = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                    
                    for photo in photoArray {
                        let url = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
                        let photo = Photo(imageURL: url, context: privateContext)
                        photo.pin = pin
                    }
                    
                    self.coreDataStack.saveChanges()
                    
                } else {
                    print("Error finding photoArray in photosDictionary")
                }
            }
        }
    }
    
    func downloadPhotosForPin(pinObjectID: NSManagedObjectID) {
        
        let privateContext = coreDataStack.privateManagedObjectContext
        
        //print("Downloading")
        
        privateContext.perform {
            
            if let pin = privateContext.object(with: pinObjectID) as? Pin {
                
                let photos = pin.photos!
                
                for photo in photos {
                    let photo = photo as! Photo
                    if let url = URL(string: photo.imageURL!) {
                        if let photoData = try? Data(contentsOf: url) {
                            photo.imageData = photoData
                        } else {
                            print("Error photoData not working!")
                        }
                    } else {
                        print("Error with photo url")
                    }
                }
                print("Number of photos: \(photos.count)")
            } else {
                print("Error no pin found!")
            }
            
            self.coreDataStack.saveChanges()
        }
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> CoreDataManager {
        struct Singleton {
            static var sharedInstace = CoreDataManager()
        }
        return Singleton.sharedInstace
    }
}
