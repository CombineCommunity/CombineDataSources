//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine
import CombineDataSources

struct Person: Hashable {
  let name: String
}

class PersonCell: UITableViewCell {
  @IBOutlet var nameLabel: UILabel!
}

class ViewController: UIViewController {
  enum Demo: Int, RawRepresentable {
    case plain, multiple, sections, noAnimations
  }

  @IBOutlet var tableView: UITableView!
  
  // The kind of demo to show
  var demo: Demo = .plain
  
  // Test data set to use
  let first = [
    [Person(name: "Julia"), Person(name: "Vicki"), Person(name: "Pete")],
    [Person(name: "Jane"), Person(name: "Jim")],
  ]
  let second = [
    [Person(name: "Pete"), Person(name: "Vicki")],
    [Person(name: "Jim")],
  ]
  
  // Publisher to emit data to the table
  var data = PassthroughSubject<[[Person]], Never>()
  
  private var flag = false
  
  // Emits values out of `data`
  func reload() {
    data.send(flag ? first : second)
    flag.toggle()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      self?.reload()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    switch demo {
    case .plain:
      // A plain list with a single section -> Publisher<[Person], Never>
      data
        .map { $0[0] }
        .subscribe(tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(model.name)"
        }))
      
    case .multiple:
      // Table with sections -> Publisher<[[Person]], Never>
      data
        .subscribe(tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(model.name)"
        }))

    case .sections:
      // Table with section driven by `Section` models -> Publisher<[Section<Person>], Never>
      data
        .map { sections in
          return sections.map { persons -> Section<Person> in
            return Section(header: "Header", items: persons, footer: "Footer")
          }
        }
        .subscribe(tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(model.name)"
        }))
      
    case .noAnimations:
      // Use custom controller to disable animations
      let controller = TableViewItemsController<[[Person]]>(cellIdentifier: "Cell", cellType: PersonCell.self) { cell, indexPath, person in
        cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(person.name)"
      }
      controller.animated = false
      
      data
        .subscribe(tableView.sectionsSubscriber(controller))
    }

    reload()
  }
}
