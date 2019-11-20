//
//  BreedListViewController.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/18/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import UIKit
import CoreData

class BreedListViewController: UITableViewController, DataControllerContainer {

    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Breed>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = dataController.fetchedResultsControllerForDogBreeds(delegate: self)
        
        loadBreedsIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dogViewController = segue.destination as? DogCollectionViewController, let indexPath = tableView.indexPathForSelectedRow {
            let breed = fetchedResultsController.object(at: indexPath)
            
            dogViewController.dataController = dataController
            dogViewController.breed = breed
        }
    }
    
    // MARK: Actions
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        dataController.deleteAllData {
            self.loadBreedsIfNeeded()
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else { return 0 }
        return section.numberOfObjects
    }
    
    override  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath)
    
        let breed = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = breed.name
        
        if let count = breed.dogs?.count, count > 0 {
            cell.detailTextLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: count),
                                                                         number: .decimal)
        } else {
            cell.detailTextLabel?.text = "Tap to load"
        }
        
        return cell
    }
}

// MARK: NSFetchedResultsControllerDelegate

extension BreedListViewController: NSFetchedResultsControllerDelegate {
        
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError("Index path should be not nil") }
            tableView.insertRows(at: [indexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            tableView.reloadRows(at: [indexPath], with: .none)
        case .move:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            guard let newIndexPath = newIndexPath else { fatalError("New index path should be not nil") }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

private extension BreedListViewController {
    
    func loadBreedsIfNeeded() {
        do { try fetchedResultsController.performFetch() } catch { fatalError("This should never happen") }
        
        tableView.reloadData()
        
        dataController.loadDogBreeds {
            print("Loaded dog breeds")
        }
    }
}
