//
//  DataController.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/17/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistenceContainer : NSPersistentContainer
    
    init(modelName : String) {
        persistenceContainer = NSPersistentContainer(name: modelName)
    }
    
    var viewContext : NSManagedObjectContext {
        return persistenceContainer.viewContext
    }
    
    var backgroundContext : NSManagedObjectContext!
    
    func configContext() {
        backgroundContext = persistenceContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load (completion : (() -> Void)? = nil){
        persistenceContainer.loadPersistentStores { storeDescription , error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configContext()
            completion?()
            
        }
    }
    
}

