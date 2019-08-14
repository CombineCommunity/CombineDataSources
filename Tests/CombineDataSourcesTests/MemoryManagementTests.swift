import XCTest
import UIKit
@testable import CombineDataSources

final class MemoryManagementTests: XCTestCase {
  func testControllerOwnsTableViewAndDataSource() {
    let ctr: TableViewItemsController<[[Model]]>? = TableViewItemsController<[[Model]]>(cellIdentifier: "Cell", cellType: UITableViewCell.self) { (cell, indexPath, model) in
      //
    }

    // Configure the controller
    var tableView: UITableView? = UITableView()
    tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    var dataSource: TestDataSource? = TestDataSource()
    
    ctr!.tableView = tableView
    ctr!.dataSource = dataSource
    ctr!.updateCollection([dataSet1, dataSet1])
    
    tableView = nil
    XCTAssertNotNil(ctr!.tableView)
    
    dataSource = nil
    XCTAssertNotNil(ctr!.dataSource)
  }
}
