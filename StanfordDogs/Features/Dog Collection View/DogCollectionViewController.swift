//
//  DogCollectionViewController.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/19/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import UIKit
import CoreData

class DogCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching, DataControllerContainer {
    
    var dataController: DataController!
    
    var breed: Breed!
    
    var fetchedResultsController: NSFetchedResultsController<Dog>!
        
    private lazy var objectChanges = [() -> Void]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = breed?.name
        
        collectionView.collectionViewLayout = createLayout()
        
        fetchedResultsController = dataController.fetchedResultsControllerForDogsOfBreed(breed, delegate: self)
        
        loadDogsIfNeeded()
    }

    // MARK: UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let dog = fetchedResultsController.object(at: indexPath)
            loadImageForDog(dog, at: indexPath)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DogCell", for: indexPath) as! DogCell

        let dog = fetchedResultsController.object(at: indexPath)
        
        if let image = dog.thumbnail?.image {
            cell.imageView.image = image
        } else {
            loadImageForDog(dog, at: indexPath, cell: cell)
        }
        
        return cell
    }
    
}


extension DogCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectChanges.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError("Index path should be not nil") }
            objectChanges.append({ self.collectionView.insertItems(at: [indexPath]) })
        case .update:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            objectChanges.append({ self.collectionView.reloadItems(at: [indexPath]) })
        case .move:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            guard let newIndexPath = newIndexPath else { fatalError("New index path should be not nil") }
            objectChanges.append({ self.collectionView.deleteItems(at: [indexPath]) })
            objectChanges.append({ self.collectionView.insertItems(at: [newIndexPath]) })
        case .delete:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            objectChanges.append({ self.collectionView.deleteItems(at: [indexPath]) })
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ [weak self] in
            self?.objectChanges.forEach { $0() }
        })
    }
}


private extension DogCollectionViewController {
    
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            let contentSize = layoutEnvironment.container.effectiveContentSize
            let columns = contentSize.width > 800 ? 3 : 2
            let spacing = CGFloat(2)
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalWidth(0.5))
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(0.5))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing

            return section
        }
        return layout
    }
    
    func loadDogsIfNeeded() {
        do { try fetchedResultsController.performFetch() } catch { fatalError("This should never happen") }
        
        collectionView.reloadData()
        
        dataController.loadDogsForBreed(breed) {
            print("Loaded dogs for \(self.breed.name ?? "?")")
        }
    }
    
    func loadImageForDog(_ dog: Dog, at indexPath: IndexPath, cell: DogCell? = nil) {
        guard let photo = dog.thumbnail else { return }
        
        if let image = photo.image {
            cell?.imageView.image = image
            return
        }
        
        dataController.loadImageForPhoto(photo) {
            guard photo.remoteURL == dog.thumbnail?.remoteURL else { return }
            cell?.imageView.image = photo.image
        }
    }
}
