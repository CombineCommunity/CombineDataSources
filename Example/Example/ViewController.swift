//
//  ViewController.swift
//  Example
//
//  Created by Marin Todorov on 8/9/19.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import UIKit
import Combine
import CombineDataSources

struct Person: Equatable {
  let name: String
}

class PersonCell: UITableViewCell {
  @IBOutlet var nameLabel: UILabel!
}

enum Demo: Int, RawRepresentable {
  case plain, multiple, sections, noAnimations
}

class ViewController: UIViewController {
  @IBOutlet var tableView: UITableView!
  
  // The kind of demo to show
  var demo: Demo = .plain
  
  // Test data set to use
  let first = [
    [Person(name: "Julia"), Person(name: "Vicki"), Person(name: "Pete")],
    [Person(name: "Jim"), Person(name: "Jane")],
  ]
  let second = [
    [Person(name: "Vicki")],
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
        .receive(subscriber: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(model.name)"
        }))
      
    case .multiple:
      // Table with sections -> Publisher<[[Person]], Never>
      data
        .receive(subscriber: tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
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
        .receive(subscriber: tableView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(model.name)"
        }))
      
    case .noAnimations:
      // Use custom controller to disable animations
      let controller = TableViewItemsController<[[Person]]>(cellIdentifier: "Cell", cellType: PersonCell.self) { cell, indexPath, person in
        cell.nameLabel.text = "\(indexPath.section+1).\(indexPath.row+1) \(person.name)"
      }
      controller.animated = false
      
      data
        .receive(subscriber: tableView.sectionsSubscriber(controller))
    }

    reload()
  }
}
