//
//  ViewController.swift
//  PresentTableViewModelDemo
//
//  Created by Patrick Niemeyer on 10/17/18.
//  Copyright © 2018 co.present. All rights reserved.
//

import UIKit
import PresentTableViewModel
import Then
import TinyConstraints
import RxSwift

class ViewController: UIViewController {

    // A plain UITableView
    let tableView = UITableView()
    
    // A plain UISearchBar
    let searchBar = UISearchBar()
    
    // The PresentTableViewModel that will serve as the table view dataSource
    let tableViewModel = TableViewModel()
    
    let disposal = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Init the search bar and bind it to our model
        searchBar.do {
            $0.barTintColor = .white
            $0.placeholder = "Search"
            view.addSubview($0)
            $0.topToSuperview(usingSafeArea: true)
            $0.widthToSuperview()
            
            // Note: We use Rx here but you don't have to.
            $0.rx.text.bind { [weak self] text in
                self?.tableViewModel.searchText = SearchText.forText(text)
            }.disposed(by: disposal)
            $0.rx.searchButtonClicked.bind { [weak self] in
                self?.view.endEditing(false)
            }.disposed(by: disposal)
        }
        
        // Init the UITableView and bind it to our model
        tableView.do {
            $0.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            $0.separatorColor = .lightGray
            $0.rowHeight = 60
            $0.sectionHeaderHeight = 50
            view.addSubview($0)
            $0.topToBottom(of: searchBar)
            $0.edgesToSuperview(excluding: .top)
            $0.bind(model: tableViewModel)
            
            $0.rx.didScroll.bind { [weak self] in
                self?.view.endEditing(false)
            }.disposed(by: disposal)
        }
        
        // Add the Person section
        let personSection = tableViewModel
            .addSection(cellType: PersonCell.self, title: "People")
            .initCell { cell in
                // Do any additional cell initialization here.
            }.filter { (row: Person, searchText: String) in
                // Provide filter logic
                row.name.lowercased().contains(searchText.lowercased())
            }.select { person in
                // Provide selection logic
                print("Selected person: \(person.name)")
            }

        // Add some data to the Person section
        personSection.items = (0...4).map {
            Person(image: UIImage(named: "person\($0)").unsafelyUnwrapped, name: "Person \($0)")
        }

        // Add the Animal section
        let animalSection = tableViewModel
            .addSection(cellType: AnimalCell.self, title: "Animals")
            .filter { (row: Animal, searchText: String) in
                row.species.lowercased().contains(searchText.lowercased())
            }.select { animal in
                print("Selected animal: \(animal.species)")
            }
        
        // Add some animals to the Animal section
        animalSection.items = (0...4).map {
            Animal(image: UIImage(named: "animal\($0)").unsafelyUnwrapped, species: "Animal \($0)")
        }
    }
    
    struct Person {
        let image: UIImage
        let name: String
    }
    class PersonCell: UITableViewCell, TableViewModelCell {
        typealias ModelType = Person
        func apply(model person: Person) {
            self.textLabel?.text = person.name
            self.imageView?.image = person.image
        }
    }

    struct Animal {
        let image: UIImage
        let species: String
    }
    class AnimalCell: UITableViewCell, TableViewModelCell {
        typealias ModelType = Animal
        func apply(model animal: Animal) {
            self.textLabel?.text = animal.species
            self.imageView?.image = animal.image
        }
    }
}

