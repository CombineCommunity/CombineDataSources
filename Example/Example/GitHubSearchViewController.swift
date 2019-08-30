//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine
import CombineDataSources

struct Repo: Codable, Hashable {
  let name: String
  let description: String?
}

struct SearchResults: Codable {
  let items: [Repo]
}

class GitHubSearchViewController: UIViewController, UISearchBarDelegate {
  @IBOutlet var tableView: UITableView!
  private var subscriptions = [AnyCancellable]()
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let searchText = searchBar.text, !searchText.isEmpty else { return }
    
    URLSession.shared.dataTaskPublisher(for:
      URL(string: "https://api.github.com/search/repositories?q=\(searchText)")!)
      .map { $0.0 }
      .decode(type: SearchResults.self, decoder: JSONDecoder())
      .map { $0.items }
      .replaceError(with: [])
      .receive(on: DispatchQueue.main)
      .bind(subscriber: tableView.rowsSubscriber(cellIdentifier: "Cell", cellType: UITableViewCell.self, cellConfig: { (cell, ip, repo) in
        cell.textLabel!.text = repo.name
        cell.detailTextLabel!.text = repo.description
      }))
      .store(in: &subscriptions)
  }
}
