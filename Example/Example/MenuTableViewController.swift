//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit

class MenuTableViewController: UITableViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let rowIndex = (sender as! UITableViewCell).tag
    
    (segue.destination as? ViewController)?.demo = ViewController.Demo(rawValue: rowIndex)!
    (segue.destination as? CollectionViewController)?.demo = CollectionViewController.Demo(rawValue: rowIndex)!
    (segue.destination as? BatchesViewController)?.demo = BatchesViewController.Demo(rawValue: rowIndex)!
  }
}
