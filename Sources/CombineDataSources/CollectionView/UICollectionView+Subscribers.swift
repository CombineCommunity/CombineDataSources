//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine

extension UICollectionView {
    
    /// A collection view specific `Subscriber` that receives `[[Element]]` input and updates a sectioned collection view.
    /// - Parameter cellIdentifier: The Cell ID to use for dequeueing table cells.
    /// - Parameter cellType: The required cell type for table rows.
    /// - Parameter cellConfig: A closure that receives an initialized cell and a collection element
    ///     and configures the cell for displaying in its containing table view.
    public func sectionsSubscriber<CellType, Items>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CollectionViewItemsController<Items>.CellConfig<Items.Element.Element, CellType>)
        -> AnySubscriber<Items, Never> where CellType: UICollectionViewCell,
        Items: RandomAccessCollection,
        Items.Element: RandomAccessCollection,
        Items.Element: Equatable {
            
            return sectionsSubscriber(.init(cellIdentifier: cellIdentifier, cellType: cellType, cellConfig: cellConfig))
    }
    
    /// A table view specific `Subscriber` that receives `[[Element]]` input and updates a sectioned table view.
    /// - Parameter source: A configured `CollectionViewItemsController<Items>` instance.
    public func sectionsSubscriber<Items>(_ source: CollectionViewItemsController<Items>)
        -> AnySubscriber<Items, Never> where
        Items: RandomAccessCollection,
        Items.Element: RandomAccessCollection,
        Items.Element: Equatable {
            
            source.collectionView = self
            dataSource = source
            
            return AnySubscriber<Items, Never>(receiveSubscription: { subscription in
                subscription.request(.unlimited)
            }, receiveValue: { [weak self] items -> Subscribers.Demand in
                guard let self = self else { return .none }
                
                if self.dataSource == nil {
                    self.dataSource = source
                }
                
                source.updateCollection(items)
                return .unlimited
            }) { _ in }
    }
    
    /// A table view specific `Subscriber` that receives `[Element]` input and updates a single section table view.
    /// - Parameter cellIdentifier: The Cell ID to use for dequeueing table cells.
    /// - Parameter cellType: The required cell type for table rows.
    /// - Parameter cellConfig: A closure that receives an initialized cell and a collection element
    ///     and configures the cell for displaying in its containing table view.
    public func itemsSubscriber<CellType, Items>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CollectionViewItemsController<[Items]>.CellConfig<Items.Element, CellType>)
        -> AnySubscriber<Items, Never> where CellType: UICollectionViewCell,
        Items: RandomAccessCollection,
        Items: Equatable {
            
            return itemsSubscriber(.init(cellIdentifier: cellIdentifier, cellType: cellType, cellConfig: cellConfig))
    }
    
    /// A table view specific `Subscriber` that receives `[Element]` input and updates a single section table view.
    /// - Parameter source: A configured `CollectionViewItemsController<Items>` instance.
    public func itemsSubscriber<Items>(_ source: CollectionViewItemsController<[Items]>)
        -> AnySubscriber<Items, Never> where
        Items: RandomAccessCollection,
        Items: Equatable {
            
            source.collectionView = self
            dataSource = source
            
            return AnySubscriber<Items, Never>(receiveSubscription: { subscription in
                subscription.request(.unlimited)
            }, receiveValue: { [weak self] items -> Subscribers.Demand in
                guard let self = self else { return .none }
                
                if self.dataSource == nil {
                    self.dataSource = source
                }
                
                source.updateCollection([items])
                return .unlimited
            }) { _ in }
    }
}

