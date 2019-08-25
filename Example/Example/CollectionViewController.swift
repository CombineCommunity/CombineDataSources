//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine
import CombineDataSources

class PersonCollectionCell: UICollectionViewCell {
  @IBOutlet var nameLabel: UILabel!
  @IBOutlet var image: UIImageView!
  private var subscriptions = [AnyCancellable]()
  
  var imageURL: URL! {
    didSet {
      URLSession.shared.dataTaskPublisher(for: imageURL)
        .compactMap { UIImage(data: $0.data) }
        .replaceError(with: UIImage())
        .receive(on: DispatchQueue.main)
        .assign(to: \.image, on: image)
        .store(in: &subscriptions)
    }
  }
}

class CollectionViewController: UIViewController {
  enum Demo: Int, RawRepresentable {
    case plain, multiple, sections, noAnimations
  }

  @IBOutlet var collectionView: UICollectionView!
  
  // The kind of demo to show
  var demo: Demo = .plain
  
  // Test data set to use
  let first = [
    [Person(name: "Julia"), Person(name: "Vicki"), Person(name: "Pete")],
    [Person(name: "Jim"), Person(name: "Jane")],
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
        .subscribe(collectionView.itemsSubscriber(cellIdentifier: "Cell", cellType: PersonCollectionCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = model.name
          cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(model.name)")!
        }))
    
    case .multiple:
      // Table with sections -> Publisher<[[Person]], Never>
      data
        .subscribe(collectionView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCollectionCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = model.name
          cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(model.name)")!
        }))

    case .sections:
      // Table with section driven by `Section` models -> Publisher<[Section<Person>], Never>
      data
        .map { sections in
          return sections.map { persons -> Section<Person> in
            return Section(items: persons)
          }
        }
        .subscribe(collectionView.sectionsSubscriber(cellIdentifier: "Cell", cellType: PersonCollectionCell.self, cellConfig: { cell, indexPath, model in
          cell.nameLabel.text = model.name
          cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(model.name)")!
        }))

    case .noAnimations:
      // Use custom controller to disable animations
      let controller = CollectionViewItemsController<[[Person]]>(cellIdentifier: "Cell", cellType: PersonCollectionCell.self) { cell, indexPath, person in
        cell.nameLabel.text = person.name
        cell.imageURL = URL(string: "https://api.adorable.io/avatars/100/\(person.name)")!
      }
      controller.animated = false
      
      data
        .subscribe(collectionView.sectionsSubscriber(controller))
    }
    
    reload()
  }
}
