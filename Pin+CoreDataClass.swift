//
//  Pin+CoreDataClass.swift
//  Concurrency
//
//  Created by Marc Boanas on 02/05/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    convenience init(longitude: Double, latitude: Double, pages: Int = 1, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.longitude = longitude
            self.latitude = latitude
            self.pages = pages
            self.creationDate = Date()
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
