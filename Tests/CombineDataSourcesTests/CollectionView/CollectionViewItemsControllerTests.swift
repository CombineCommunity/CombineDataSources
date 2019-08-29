import XCTest
import UIKit
@testable import CombineDataSources

final class CollectionViewItemsControllerTests: XCTestCase {
  
  func testDataSource() {
    // Make the controller
    var lastIndexPath: IndexPath? = nil
    
    let ctr = CollectionViewItemsController<[[Model]]>(cellIdentifier: "Cell", cellType: UICollectionViewCell.self) { (cell, indexPath, model) in
      lastIndexPath = indexPath
    }

    // Configure the controller
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
    ctr.collectionView = collectionView
    ctr.updateCollection([dataSet1, dataSet1])
    
    // Test data source methods
    XCTAssertEqual(2, ctr.numberOfSections(in: collectionView))
    XCTAssertEqual(3, ctr.collectionView(collectionView, numberOfItemsInSection: 0))
    
    XCTAssertNil(lastIndexPath)
    let cell = ctr.collectionView(collectionView, cellForItemAt: IndexPath(row: 1, section: 0))
    XCTAssertNotNil(cell)
    XCTAssertEqual(1, lastIndexPath?.row)
    
    // Test an update
    ctr.updateCollection([dataSet1])
    XCTAssertEqual(1, ctr.numberOfSections(in: collectionView))
  }

  func testSections() {
    var lastModel: Model?
    let ctr = CollectionViewItemsController<[Section<Model>]>(cellIdentifier: "Cell", cellType: UICollectionViewCell.self) { (cell, indexPath, model) in
      lastModel = model
    }

    // Configure the controller
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
    ctr.collectionView = collectionView
    ctr.updateCollection(dataSet2)
        
    XCTAssertNil(lastModel)
    let cell = ctr.collectionView(collectionView, cellForItemAt: IndexPath(row: 0, section: 0))
    XCTAssertNotNil(cell)
    XCTAssertEqual("test model", lastModel?.text)
  }
}
