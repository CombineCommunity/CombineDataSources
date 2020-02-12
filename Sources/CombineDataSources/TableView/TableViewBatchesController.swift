//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine

public class TableViewBatchesController<Element: Hashable> {
    // Input
    public let reload = PassthroughSubject<Void, Never>()
    public let loadNext = PassthroughSubject<Void, Never>()
    
    // Output
    public let loadError = CurrentValueSubject<Error?, Never>(nil)
    
    // Private user interface
    private let tableView: UITableView
    private var batchesDataSource: BatchesDataSource<Element>!
    private var spin: UIActivityIndicatorView = {
        let spin = UIActivityIndicatorView(style: .large)
        spin.tintColor = .systemGray
        spin.startAnimating()
        spin.alpha = 0
        return spin
    }()
    
    private var itemsController: TableViewItemsController<[[Element]]>!
    private var subscriptions = [AnyCancellable]()
    
    public convenience init(tableView: UITableView, itemsController: TableViewItemsController<[[Element]]>, initialToken: Data?, loadItemsWithToken: @escaping (Data?) -> AnyPublisher<BatchesDataSource<Element>.LoadResult, Error>) {
        self.init(tableView: tableView)
        
        // Create a token-based batched data source.
        batchesDataSource = BatchesDataSource<Element>(
            input: BatchesInput(reload: reload.eraseToAnyPublisher(), loadNext: loadNext.eraseToAnyPublisher()),
            initialToken: initialToken,
            loadItemsWithToken: loadItemsWithToken
        )
        
        self.itemsController = itemsController
        
        bind()
    }
    
    public convenience init(tableView: UITableView, itemsController: TableViewItemsController<[[Element]]>, loadPage: @escaping (Int) -> AnyPublisher<BatchesDataSource<Element>.LoadResult, Error>) {
        self.init(tableView: tableView)
        
        // Create a paged data source.
        self.batchesDataSource = BatchesDataSource<Element>(
            input: BatchesInput(reload: reload.eraseToAnyPublisher(), loadNext: loadNext.eraseToAnyPublisher()),
            loadPage: loadPage
        )
        
        self.itemsController = itemsController
        
        bind()
    }
    
    private init(tableView: UITableView) {
        self.tableView = tableView
        
        // Add bottom offset.
        var newInsets = tableView.contentInset
        newInsets.bottom += 60
        tableView.contentInset = newInsets
        
        // Add spinner.
        tableView.addSubview(spin)
    }
    
    private func bind() {
        // Display items in table view.
        batchesDataSource.output.$items
            .receive(on: DispatchQueue.main)
            .bind(subscriber: tableView.rowsSubscriber(itemsController))
            .store(in: &subscriptions)
        
        // Show/hide spinner.
        batchesDataSource.output.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.spin.center = CGPoint(x: self.tableView.frame.width/2, y: self.tableView.contentSize.height + 30)
                    self.spin.alpha = 1
                    self.tableView.scrollRectToVisible(CGRect(x: 0, y: self.tableView.contentOffset.y + self.tableView.frame.height, width: 10, height: 10), animated: true)
                } else {
                    self.spin.alpha = 0
                }
        }
        .store(in: &subscriptions)
        
        // Bind errors.
        batchesDataSource.output.$error
            .subscribe(loadError)
            .store(in: &subscriptions)
        
        // Observe for table dragging.
        let didDrag = Publishers.CombineLatest(Just(tableView), tableView.publisher(for: \.contentOffset))
            .map { $0.0.isDragging }
            .scan((from: false, to: false)) { result, value -> (from: Bool, to: Bool) in
                return (from: result.to, to: value)
        }
        .filter { tuple -> Bool in
            tuple == (from: true, to: false)
        }
        
        // Observe table offset and trigger loading next page at bottom
        Publishers.CombineLatest(Just(tableView), didDrag)
            .map { $0.0 }
            .filter { table -> Bool in
                return isAtBottom(of: table)
        }
        .sink { [weak self] _ in
            self?.loadNext.send()
        }
        .store(in: &subscriptions)
    }
}

fileprivate func isAtBottom(of tableView: UITableView) -> Bool {
    let height = tableView.frame.size.height
    let contentYoffset = tableView.contentOffset.y
    let distanceFromBottom = tableView.contentSize.height - contentYoffset
    return distanceFromBottom <= height
}
