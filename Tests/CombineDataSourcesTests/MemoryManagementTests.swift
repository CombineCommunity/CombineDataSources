import XCTest
import UIKit
import Combine
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
    
  func testBind() {
    let expectation1 = expectation(description: "subscribed")
    let expectation2 = expectation(description: "value")

    var subscriptions = [AnyCancellable]()
    var sub: AnySubscriber<String, Never>?
    
    sub = AnySubscriber<String, Never>(
      receiveSubscription: { sub in
        expectation1.fulfill()
      },
      receiveValue: { value -> Subscribers.Demand in
        expectation2.fulfill()
        return .unlimited
      })
    { (completion) in
      XCTFail("Binding sent completion event")
    }
    
    DispatchQueue.main.async {
      let data = PassthroughSubject<String, Never>()
      data
        .bind(subscriber: sub!)
        .store(in: &subscriptions)

      data.send("asdasd") // will be passed on
      data.send(completion: .finished) // will be filtered
    }
    wait(for: [expectation1, expectation2], timeout: 1)
  }
}
