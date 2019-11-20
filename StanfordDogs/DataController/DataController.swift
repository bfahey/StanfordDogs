//
//  DataController.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/18/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import CoreData

class DataController {
    
    // MARK: - URLSession
    
    private var session: URLSession = .shared
    
    // MARK: - Core Data stack

    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "StanfordDogs")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Breeds
    
    func fetchedResultsControllerForDogBreeds(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Breed> {
        let request: NSFetchRequest<Breed> = Breed.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Breed.name, ascending: true)]
        
        let frc = NSFetchedResultsController<Breed>(fetchRequest: request,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        frc.delegate = delegate
        
        return frc
    }
    
    /// Delete all data in the PersistentContainer.
    func deleteAllData(queue: DispatchQueue = .main, completion: @escaping () -> Void) {
        self.persistentContainer.performBackgroundTask { (context) in
            defer {
                queue.async { completion() }
            }
            
            ["Breed", "Dog", "Photo"].forEach {
                let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: $0)
                let delete = NSBatchDeleteRequest(fetchRequest: request)
                do {
                    try context.execute(delete)
                    try context.save()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    /// Load all dog breeds from the Dog API.
    @discardableResult
    func loadDogBreeds(queue: DispatchQueue = .main, completion: @escaping () -> Void) -> Progress {
        let request = DogAPIRequest<[String]>(url: DogAPI.breedsList)
        
        let task = request.load(with: session) { result in
            guard let breedNames = try? result.get() else {
                queue.async { completion() }
                return
            }
            
            self.persistentContainer.performBackgroundTask { (context) in
                context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
                
                defer {
                    queue.async { completion() }
                }
                    
                // Fetch all breeds that exist on disk with the given array of names.
                let request: NSFetchRequest<Breed> = Breed.fetchRequest()
                request.predicate = NSPredicate(format: "name IN %@", breedNames)
                request.returnsObjectsAsFaults = false
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Breed.name, ascending: true)]
                
                do {
                    let matchingBreeds = try context.fetch(request)
                    
                    // Calculate which breeds to save.
                    let breedNamesAlreadyOnDisk = Set(matchingBreeds.compactMap { $0.name })
                    let namesToBeAdded = Set(breedNames).subtracting(breedNamesAlreadyOnDisk)
                    
                    // Create new breeds!
                    for name in namesToBeAdded {
                        let newBreed = Breed(context: context)
                        newBreed.name = name
                    }
                    
                    // Save the background context to populate the main context.
                    if context.hasChanges {
                        try context.save()
                    }
                    
                    // Free up some memory.
                    context.reset()
                } catch {
                    print("Failed to save background context!")
                }
            }
        }
        
        return task.progress
    }
    
    // MARK: Dogs
    
    func fetchedResultsControllerForDogsOfBreed(_ breed: Breed, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Dog> {
        let request: NSFetchRequest<Dog> = Dog.fetchRequest()
        request.predicate = NSPredicate(format: "breed = %@", breed)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Dog.id, ascending: true)]
        
        let frc = NSFetchedResultsController<Dog>(fetchRequest: request,
                                                  managedObjectContext: persistentContainer.viewContext,
                                                  sectionNameKeyPath: nil,
                                                  cacheName: nil)
        frc.delegate = delegate
        
        return frc
    }
    
    /// Load all dogs for the given breed.
    @discardableResult
    func loadDogsForBreed(_ breed: Breed, queue: DispatchQueue = .main, completion: @escaping () -> Void) -> Progress {
        let url = DogAPI.breedImages(for: breed.name ?? "")
        
        let request = DogAPIRequest<[String]>(url: url)
        
        let task = request.load { result in
            guard let remoteURLStrings = try? result.get() else {
                queue.async { completion() }
                return
            }
            
            self.persistentContainer.performBackgroundTask { (context) in
                context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
                
                defer {
                    queue.async { completion() }
                }
                    
                // Fetch the breed on the local context. Cross-context objects are not allowed.
                let localBreed = context.object(with: breed.objectID) as! Breed
                
                // Fetch all dogs that exist on disk that match the given breed.
                let request: NSFetchRequest<Dog> = Dog.fetchRequest()
                request.predicate = NSPredicate(format: "breed = %@", localBreed)
                request.returnsObjectsAsFaults = false
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Dog.id, ascending: true)]
                
                do {
                    let matchingDogs = try context.fetch(request)
                    
                    let remoteURLStringsAlreadyOnDisk = Set(matchingDogs.compactMap { $0.id })
                    let urlStringsToBeAdded = Set(remoteURLStrings).subtracting(remoteURLStringsAlreadyOnDisk)
                    
                    // Create the dogs!
                    for urlString in urlStringsToBeAdded {
                        let thumbnailPhoto = Photo(context: context)
                        thumbnailPhoto.remoteURL = URL(string: urlString)
                        
                        let newDog = Dog(context: context)
                        newDog.id = urlString
                        newDog.breed = localBreed
                        newDog.thumbnail = thumbnailPhoto
                    }
                    
                    // Save the background context to populate the main context.
                    if context.hasChanges {
                        try context.save()
                    }
                    
                    // Free up some memory.
                    context.reset()
                } catch {
                    print("Failed to save background context! \(error)")
                }
            }
        }
        
        return task.progress
    }
    
    /// Load the image for the given photo.
    @discardableResult
    func loadImageForPhoto(_ photo: Photo, queue: DispatchQueue = .main, completion: @escaping () -> Void) -> Progress {
        let request = ImageRequest(url: photo.remoteURL!)
        
        let task = request.load(with: session) { (result) in
            guard let image = try? result.get() else {
                queue.async { completion() }
                return
            }
            
            let context = self.persistentContainer.viewContext
            context.perform {
                // The photos's `data` property uses Core Data's "Allows External Storage" feature.
                // Core Data will automatically move the binary data from the database column
                // to an external directory as it approaches 1MB in size.
                photo.data = image.jpegData(compressionQuality: 0.8)
                
                queue.async { completion() }
            }
        }
        
        return task.progress
    }
}
