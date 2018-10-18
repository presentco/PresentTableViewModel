//
//  TableViewModel+Rx.swift
//  Pods-PresentTableViewModelDemo
//
//  Created by Patrick Niemeyer on 10/17/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

// MARK: Rx Extensions

extension TableViewModel
{
    public func bind(searchTextSource: Observable<SearchText>?) -> Disposable {
        return searchTextSource?.bind { [weak self] searchText in
                self?.searchText = searchText
            } ?? Disposables.create()
    }
}

extension TableViewModel.Section
{
    /// Observe selected rows on this section
    public var selected: Observable<C.ModelType> {
        return tableView.unwrappedOrFatal()
            .rx.itemSelected
            .filter { [weak self] index in
                return index.section == self?.sectionIndex
            }.map { [weak self] (index:IndexPath)->C.ModelType? in
                let section = self?.tableViewModel?.filteredModel[index.section] as? TableViewModel.Section<C>
                return section?.items[index.item]
            }.flatMap { Observable.from(optional: $0) } // remove nils from weak self
    }
}
