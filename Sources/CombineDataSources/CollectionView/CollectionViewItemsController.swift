//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine

/// A collection view controller acting as data source.
/// `CollectionType` needs to be a collection of collections to represent sections containing rows.
public class CollectionViewItemsController<CollectionType>: NSObject, UICollectionViewDataSource
  where CollectionType: RandomAccessCollection,
  CollectionType.Index == Int,
  CollectionType.Element: Hashable,
  CollectionType.Element: RandomAccessCollection,
  CollectionType.Element.Index == Int,
  CollectionType.Element.Element: Hashable {
  
  public typealias Element = CollectionType.Element.Element
  public typealias CellFactory<Element: Equatable> = (CollectionViewItemsController<CollectionType>, UICollectionView, IndexPath, Element) -> UICollectionViewCell
  public typealias CellConfig<Element, Cell> = (Cell, IndexPath, Element) -> Void
  
  private let cellFactory: CellFactory<Element>
  private var collection: CollectionType!
  
  /// Should the table updates be animated or static.
  public var animated = true
  
  /// The collection view for the data source
  var collectionView: UICollectionView!
  
  /// A fallback data source to implement custom logic like indexes, dragging, etc.
  public var dataSource: UICollectionViewDataSource?
  
  // MARK: - Init
  public init<CellType>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CellConfig<Element, CellType>) where CellType: UICollectionViewCell {
    cellFactory = { dataSource, collectionView, indexPath, value in
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! CellType
      cellConfig(cell, indexPath, value)
      return cell
    }
  }
  
  private init(cellFactory: @escaping CellFactory<Element>) {
    self.cellFactory = cellFactory
  }
  
  deinit {
    debugPrint("Controller is released")
  }
  
  // MARK: - Update collection
  private let fromRow = {(section: Int) in return {(row: Int) in return IndexPath(row: row, section: section)}}
  
  func updateCollection(_ items: CollectionType) {
    // If the changes are not animatable, reload the table
    guard animated, collection != nil, items.count == collection.count else {
      collection = items
      collectionView.reloadData()
      return
    }
    
    // Commit the changes to the collection view sections
    collectionView.performBatchUpdates({[unowned self] in
      for sectionIndex in 0..<items.count {
        let rowAtIndex = self.fromRow(sectionIndex)
        let changes = delta(newList: items[sectionIndex], oldList: collection[sectionIndex])
        
        collectionView.deleteItems(at: changes.removals.map(rowAtIndex))
        collectionView.insertItems(at: changes.insertions.map(rowAtIndex))
        for move in changes.moves {
          collectionView.moveItem(at: rowAtIndex(move.0), to: rowAtIndex(move.1))
        }
      }
      collection = items
    }, completion: nil)
  }
  
  // MARK: - UITableViewDataSource protocol
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    guard collection != nil else { return 0 }
    return collection.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return collection[section].count
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    cellFactory(self, collectionView, indexPath, collection[indexPath.section][indexPath.row])
  }
  
  // MARK: - Fallback data source object
  override public func forwardingTarget(for aSelector: Selector!) -> Any? {
    return dataSource
  }
}
