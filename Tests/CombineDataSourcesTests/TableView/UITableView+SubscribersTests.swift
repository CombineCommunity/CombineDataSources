//
//  File.swift
//  
//
//  Created by Marin Todorov on 8/13/19.
//

import XCTest
import UIKit
@testable import CombineDataSources

final class UITableView_SubscribersTests: XCTestCase {
  func testTableController() {
    let ctr = TableViewItemsController<[[Model]]>(cellIdentifier: "Cell", cellType: UITableViewCell.self) { (cell, indexPath, model) in
      //
    }
    
    // Configure the controller
    let tableView = UITableView()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    
    //
    // Test rows subscriber
    //
    do {
      let subscriber = tableView.rowsSubscriber(ctr)
      _ = subscriber.receive(dataSet1)
      
      XCTAssertNotNil(tableView.dataSource)
      XCTAssertEqual(1, tableView.numberOfSections)
      XCTAssertEqual(3, tableView.numberOfRows(inSection: 0))

      _ = subscriber.receive(dataSet1 + dataSet1)
      XCTAssertEqual(6, tableView.numberOfRows(inSection: 0))
    }
    
    //
    // Test rows subscriber
    //
    do {
      let subscriber = tableView.sectionsSubscriber(ctr)
      _ = subscriber.receive([dataSet1])
      
      XCTAssertNotNil(tableView.dataSource)
      XCTAssertEqual(1, tableView.numberOfSections)
      XCTAssertEqual(3, tableView.numberOfRows(inSection: 0))
      
      _ = subscriber.receive([dataSet1, dataSet1])
      XCTAssertEqual(2, tableView.numberOfSections)
    }
  }
}
