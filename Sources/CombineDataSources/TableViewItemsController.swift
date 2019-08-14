//
//  File.swift
//  
//
//  Created by Marin Todorov on 8/9/19.
//

import UIKit
import Combine

/// A table view controller acting as data source.
/// `CollectionType` needs to be a collection of collections to represent sections containing rows.
public class TableViewItemsController<CollectionType>: NSObject, UITableViewDataSource
  where CollectionType: RandomAccessCollection,
  CollectionType.Index == Int,
  CollectionType.Element: Equatable,
  CollectionType.Element: RandomAccessCollection,
  CollectionType.Element.Index == Int,
  CollectionType.Element.Element: Equatable {
  
  public typealias Element = CollectionType.Element.Element
  public typealias CellFactory<Element: Equatable> = (TableViewItemsController<CollectionType>, UITableView, IndexPath, Element) -> UITableViewCell
  public typealias CellConfig<Element, Cell> = (Cell, IndexPath, Element) -> Void
  
  private let cellFactory: CellFactory<Element>
  private var collection: CollectionType!
  
  /// Should the table updates be animated or static.
  public var animated = true
  
  /// What transitions to use for inserting, updating, and deleting table rows.
  public var rowAnimations = (
    insert: UITableView.RowAnimation.automatic,
    update: UITableView.RowAnimation.automatic,
    delete: UITableView.RowAnimation.automatic
  )
  
  /// The table view for the data source
  var tableView: UITableView!
  
  /// A fallback data source to implement custom logic like indexes, dragging, etc.
  public var dataSource: UITableViewDataSource?
  
  // MARK: - Init
  public init<CellType>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CellConfig<Element, CellType>) where CellType: UITableViewCell {
    cellFactory = { dataSource, tableView, indexPath, value in
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CellType
      cellConfig(cell, indexPath, value)
      return cell
    }
  }
  
  private init(cellFactory: @escaping CellFactory<Element>) {
    self.cellFactory = cellFactory
  }
  
  deinit {
    print("Controller is released")
  }
  
  // MARK: - Update collection
  private let fromRow = {(section: Int) in return {(row: Int) in return IndexPath(row: row, section: section)}}
  
  func updateCollection(_ items: CollectionType) {
    // If the changes are not animatable, reload the table
    guard animated, collection != nil, items.count == collection.count else {
      collection = items
      tableView.reloadData()
      return
    }
    
    // Commit the changes to the table view sections
    tableView.beginUpdates()
    for sectionIndex in 0..<items.count {
      let changes = delta(newList: items[sectionIndex], oldList: collection[sectionIndex])
      tableView.deleteRows(at: changes.removals.map(fromRow(sectionIndex)), with: rowAnimations.delete)
      tableView.insertRows(at: changes.insertions.map(fromRow(sectionIndex)), with: rowAnimations.insert)
    }
    collection = items
    tableView.endUpdates()
  }
  
  private func delta<T>(newList: T, oldList: T) -> (insertions: [Int], removals: [Int])
    where T: RandomAccessCollection, T.Element: Equatable {
      
      let changes = newList.difference(from: oldList)
      
      let insertIndexes = changes.compactMap { change -> Int? in
        guard case CollectionDifference<T.Element>.Change.insert(let offset, _, _) = change else {
          return nil
        }
        return offset
      }
      let deleteIndexes = changes.compactMap { change -> Int? in
        guard case CollectionDifference<T.Element>.Change.remove(let offset, _, _) = change else {
          return nil
        }
        return offset
      }
      
      return (insertions: insertIndexes, removals: deleteIndexes)
  }
  
  // MARK: - UITableViewDataSource protocol
  public func numberOfSections(in tableView: UITableView) -> Int {
    guard collection != nil else { return 0 }
    return collection.count
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return collection[section].count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    cellFactory(self, tableView, indexPath, collection[indexPath.section][indexPath.row])
  }
  
  public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let sectionModel = collection[section] as? Section<CollectionType.Element.Element> else {
      return dataSource?.tableView?(tableView, titleForHeaderInSection: section)
    }
    return sectionModel.header
  }
  
  public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    guard let sectionModel = collection[section] as? Section<CollectionType.Element.Element> else {
      return dataSource?.tableView?(tableView, titleForFooterInSection: section)
    }
    return sectionModel.footer
  }
  
  // MARK: - Fallback data source object
  override public func forwardingTarget(for aSelector: Selector!) -> Any? {
    return dataSource
  }
}
