//
//  File.swift
//
//
//  Created by Marin Todorov on 8/13/19.
//

import XCTest
import UIKit
@testable import CombineDataSources

final class UICollectionView_SubscribersTests: XCTestCase {
    func testCollectionController() {
        let ctr = CollectionViewItemsController<[[Model]]>(cellIdentifier: "Cell", cellType: UICollectionViewCell.self) { (cell, indexPath, model) in
            //
        }
        
        // Configure the controller
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        //
        // Test rows subscriber
        //
        do {
            let subscriber = collectionView.itemsSubscriber(ctr)
            _ = subscriber.receive(dataSet1)
            
            XCTAssertNotNil(collectionView.dataSource)
            XCTAssertEqual(1, collectionView.numberOfSections)
            XCTAssertEqual(3, collectionView.numberOfItems(inSection: 0))
            
            _ = subscriber.receive(dataSet1 + dataSet1)
            XCTAssertEqual(6, collectionView.numberOfItems(inSection: 0))
        }
        
        //
        // Test rows subscriber
        //
        do {
            let subscriber = collectionView.sectionsSubscriber(ctr)
            _ = subscriber.receive([dataSet1])
            
            XCTAssertNotNil(collectionView.dataSource)
            XCTAssertEqual(1, collectionView.numberOfSections)
            XCTAssertEqual(3, collectionView.numberOfItems(inSection: 0))
            
            _ = subscriber.receive([dataSet1, dataSet1])
            XCTAssertEqual(2, collectionView.numberOfSections)
        }
    }
}
