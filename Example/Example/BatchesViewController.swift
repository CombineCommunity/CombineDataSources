//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine
import CombineDataSources

struct MockAPI {
  static func requestPage(pageNumber: Int) -> AnyPublisher<BatchesDataSource<String>.LoadResult, Error> {
    // Do your network request or otherwise fetch items here.
    return sampleData(.pages)
  }
  
  static func requestBatch(token: Data?) -> AnyPublisher<BatchesDataSource<String>.LoadResult, Error> {
    // Do your network request or otherwise fetch items here.
    return sampleData(.batches)
  }
}

class BatchesViewController: UIViewController {
  @IBOutlet var tableView: UITableView!
  
  enum Demo: Int, RawRepresentable {
    case pages, batchesWithToken
  }
  
  var demo: Demo!
  var controller: TableViewBatchesController<String>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Create a plain table data source.
    let itemsController = TableViewItemsController<[[String]]>(cellIdentifier: "Cell", cellType: UITableViewCell.self, cellConfig: { cell, indexPath, text in
      cell.textLabel!.text = "\(indexPath.row+1). \(text)"
    })
    
    switch demo {
    case .batchesWithToken:
      
      // Bind a batched data source to table view.
      controller = TableViewBatchesController<String>(
        tableView: tableView,
        itemsController: itemsController,
        initialToken: nil,
        loadItemsWithToken: { nextToken in
          MockAPI.requestBatch(token: nextToken)
        }
      )
      
    case .pages:
      
      // Bind a paged data source to table view.
      controller = TableViewBatchesController<String>(
        tableView: tableView,
        itemsController: itemsController,
        loadPage: { nextPage in
          return MockAPI.requestPage(pageNumber: nextPage)
        }
      )
      
    default: break
    }
  }
}
