//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine

/// A table view controller acting as data source.
/// `CollectionType` needs to be a collection of collections to represent sections containing rows.
public class TableViewItemsController<CollectionType>: NSObject, UITableViewDataSource
    where CollectionType: RandomAccessCollection,
    CollectionType.Index == Int,
    CollectionType.Element: Hashable,
    CollectionType.Element: RandomAccessCollection,
    CollectionType.Element.Index == Int,
CollectionType.Element.Element: Hashable {
    
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
    
    /// An initializer that takes a cell type and identifier and configures the controller to dequeue cells
    /// with that data and configures each cell by calling the developer provided `cellConfig()`.
    /// - Parameter cellIdentifier: A cell identifier to use to dequeue cells from the source table view
    /// - Parameter cellType: A type to cast dequeued cells as
    /// - Parameter cellConfig: A closure to call before displaying each cell
    public init<CellType>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CellConfig<Element, CellType>) where CellType: UITableViewCell {
        cellFactory = { dataSource, tableView, indexPath, value in
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CellType
            cellConfig(cell, indexPath, value)
            return cell
        }
    }
    
    
    /// An initializer that takes a closure expected to return a dequeued cell ready to be displayed in the table view.
    /// - Parameter cellFactory: A `(TableViewItemsController<CollectionType>, UITableView, IndexPath, Element) -> UITableViewCell` closure. Use the table input parameter to dequeue a cell and configure it with the `Element`'s data
    public init(cellFactory: @escaping CellFactory<Element>) {
        self.cellFactory = cellFactory
    }
    
    deinit {
        debugPrint("Controller is released")
    }
    
    // MARK: - Update collection
    private let fromRow = {(section: Int) in return {(row: Int) in return IndexPath(row: row, section: section)}}
    
    func updateCollection(_ items: CollectionType) {
        // Initial collection
        if collection == nil, animated {
            guard tableView.numberOfSections == 0 else {
                // collection is out of sync with the actual table view contents.
                collection = items
                tableView.reloadData()
                return
            }
            
            tableView.beginUpdates()
            tableView.insertSections(IndexSet(integersIn: 0..<items.count), with: rowAnimations.insert)
            for sectionIndex in 0..<items.count {
                let rowAtIndex = fromRow(sectionIndex)
                tableView.insertRows(at: (0..<items[sectionIndex].count).map(rowAtIndex), with: rowAnimations.insert)
            }
            collection = items
            tableView.endUpdates()
        }
        
        // If the changes are not animatable, reload the table
        guard animated, collection != nil, items.count == collection.count else {
            collection = items
            tableView.reloadData()
            return
        }
        
        // Commit the changes to the table view sections
        tableView.beginUpdates()
        for sectionIndex in 0..<items.count {
            let rowAtIndex = fromRow(sectionIndex)
            let changes = delta(newList: items[sectionIndex], oldList: collection[sectionIndex])
            tableView.deleteRows(at: changes.removals.map(rowAtIndex), with: rowAnimations.delete)
            tableView.insertRows(at: changes.insertions.map(rowAtIndex), with: rowAnimations.insert)
            for move in changes.moves {
                tableView.moveRow(at: rowAtIndex(move.0), to: rowAtIndex(move.1))
            }
        }
        collection = items
        tableView.endUpdates()
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

internal func delta<T>(newList: T, oldList: T) -> (insertions: [Int], removals: [Int], moves: [(Int, Int)])
    where T: RandomAccessCollection, T.Element: Hashable {
        
        let changes = newList.difference(from: oldList).inferringMoves()
        
        var insertions = [Int]()
        var removals = [Int]()
        var moves = [(Int, Int)]()
        
        for change in changes {
            switch change {
            case .insert(offset: let index, element: _, associatedWith: let associatedIndex):
                if let fromIndex = associatedIndex {
                    moves.append((fromIndex, index))
                } else {
                    insertions.append(index)
                }
            case .remove(offset: let index, element: _, associatedWith: let associatedIndex):
                if associatedIndex == nil {
                    removals.append(index)
                }
            }
        }
        return (insertions: insertions, removals: removals, moves: moves)
}
