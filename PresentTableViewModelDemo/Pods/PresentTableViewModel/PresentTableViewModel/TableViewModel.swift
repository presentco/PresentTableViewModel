//
//  UITableViewBase.swift
//  Present
//
//  Created by Patrick Niemeyer on 6/18/18.
//  Copyright © 2018 Present Company. All rights reserved.
//

import Foundation
import Then
import RxSwift

/// Type adopted by table view cells that can be managed by TableViewModel
/// A sectioned table view data source with individually typed model and cells per section.
public class TableViewModel: NSObject, UITableViewDataSource
{
    /// If true do not display sections with no rows.
    public var hideEmptySections = true

    /// Add a section to the table model, specifying the cell type and an optional title.
    /// If a table view with no sections is desired simply use one section with no title.
    public func addSection<CellType: UITableViewCell & TableViewModelCell>(
        cellType: CellType.Type, title: String? = nil, items: [CellType.ModelType] = [CellType.ModelType]()) -> Section<CellType>
    {
        guard let tableView = tableView else { fatalError("tableView not set") }
        let section = Section<CellType>(tableView: tableView, tableViewModel: self, sectionIndex: model.count, title: title, items: items)
        model.append(section)
        return section
    }
    
    public var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.dataSource = self
            } else {
                oldValue?.dataSource = nil
            }
        }
    }
    
    public var model = [TableViewModelSectionType]() {
        didSet {
            updateFiltered()
        }
    }
    
    public func sectionFor(_ indexPath: IndexPath) -> TableViewModelSectionType {
        return model[indexPath.section]
    }

    internal var filteredModel = [TableViewModelSectionType]()

    public var searchText: SearchText = .noSearch {
        didSet {
            updateFiltered()
        }
    }
    
    public func remove(atIndex indexPath: IndexPath, suppressReload: Bool = false)
    {
        self.suppressReload = suppressReload
        model[indexPath.section].remove(index: indexPath.item)
        self.suppressReload = false
    }

    // TODO:
    /// Suppress reloading table data after updating the filtered model.
    /// This is a workaround to avoid reloading the table when rows are changed
    /// as a result of a row action.
    var suppressReload = false
    
    func updateFiltered() {
        if case let .value(text) = searchText {
            filteredModel = model.map { $0.filtered(searchText: text) }
        } else {
            filteredModel = model
        }
        if !suppressReload {
            self.tableView?.reloadData()
        }
    }
    
    func isEmpty() -> Bool {
        return filteredModel.count == 0 || (hideEmptySections && filteredModel.filter { $0.count > 0 }.count == 0);
    }
    
    // MARK: UITableViewDataSource
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return filteredModel.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let model = filteredModel[section]
        if hideEmptySections && model.count == 0 {
            return nil
        } else {
            return model.title
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredModel[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        return filteredModel[indexPath.section].cellForIndex(tableView, index: indexPath.item)
    }
    
    public class Section<C: UITableViewCell & TableViewModelCell> : TableViewModelSectionType, Then
    {
        private lazy var reuseIdentifier: String = C.init().reuseIdentifier ?? ""
        
        public var title: String?
        
        public var items = [C.ModelType]() {
            didSet {
                tableViewModel?.updateFiltered()
            }
        }
        
        @discardableResult
        public func items(_ items: [C.ModelType]) -> Self {
            self.items = items
            return self
        }
        
        @discardableResult
        public func withItems(_ items: [C.ModelType]) -> Self {
            return self.items(items)
        }
        
        public var initCellBlock: ((C)->Void)?
        public var applyModelBlock: ((C,C.ModelType)->Void)?
        
        weak var tableView: UITableView?
        weak var tableViewModel: TableViewModel?
        let sectionIndex: Int
        
        public init(tableView: UITableView, tableViewModel: TableViewModel, sectionIndex: Int, title: String?, items: [C.ModelType]) {
            self.tableView = tableView
            self.tableViewModel = tableViewModel
            self.sectionIndex = sectionIndex
            self.title = title
            self.items = items
        }
        
        public func modelForIndex(_ index: Int) -> C.ModelType {
            return items[index]
        }
        
        public var filter: ((C.ModelType, String)->Bool)? {
            didSet {
                tableViewModel?.updateFiltered()
            }
        }
        
        public var select: ((C.ModelType)->Void)?

        public func reuseIdentifier(_ string: String) -> Section<C> {
            self.reuseIdentifier = string
            return self
        }

        /// The title of the section or nil for no section header
        public func title(_ string: String) -> Section<C> {
            self.title = string
            return self
        }
        public func withTitle(_ string: String) -> Section<C> {
            return title(string)
        }
        
        /// Called after the cell's initCell() method to customize newly constructed cells
        public func initCell(withBlock block: @escaping (C)->Void) -> Section<C> {
            self.initCellBlock = block
            return self
        }
        
        /// Called after the cell's applyModel() method to customize newly updated cells
        public func applyModel(withBlock block: @escaping (C,C.ModelType)->Void) -> Section<C> {
            self.applyModelBlock = block
            return self
        }
        
        public func filter(withBlock block: @escaping (C.ModelType, String)->Bool) -> Section<C> {
            self.filter = block
            return self
        }
        
        public func select(withBlock block: @escaping (C.ModelType)->Void) -> Section<C> {
            _ = self.selected.do(onNext: block).subscribe()
            return self
        }
        
        public func filtered(searchText: String) -> TableViewModelSectionType {
            guard let tableView = tableView, let tableViewModel = tableViewModel else { return self }
            let filteredItems: [C.ModelType]
            if let filter = filter {
                filteredItems = items.filter { filter($0, searchText) }
            } else {
                filteredItems = items
            }
            let filteredSection = Section<C>(tableView: tableView, tableViewModel: tableViewModel, sectionIndex: sectionIndex, title: title, items: filteredItems
            )
            filteredSection.initCellBlock = initCellBlock
            filteredSection.applyModelBlock = applyModelBlock
            return filteredSection
        }
        
        /// Reuse or create the cell
        public func cellForIndex(_ tableView: UITableView, index: Int) -> UITableViewCell
        {
            let model = modelForIndex(index)
            
            let cell =
                (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? C) ??
                    (C.init(style: .default, reuseIdentifier: reuseIdentifier).then {
                        self.initCellBlock?($0)
                    })
            cell.apply(model: model)
            applyModelBlock?(cell, model)
            
            return cell
        }
        
        public var count: Int {
            return items.count
        }
        
        public func remove(index: Int) {
            items.remove(at: index)
        }
        
    }
}

public protocol TableViewModelCell {
    associatedtype ModelType // rename ModelType
    func apply(model: ModelType)
}

public protocol TableViewModelSectionType: class {
    func cellForIndex(_ tableView: UITableView, index: Int) -> UITableViewCell
    func remove(index: Int)
    func filtered(searchText: String) -> TableViewModelSectionType // TODO: change to Self
    var count: Int { get }
    var title: String? { get }
}

// MARK: UITableView Extensions

public extension UITableView {
    public func bind(model: TableViewModel) {
        model.tableView = self
    }
}
