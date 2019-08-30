
import UIKit
import Combine
import CombineDataSources

// An example custom token type.
struct ServerToken: Codable {
  let id: UUID
  let count: Int
}

enum APIError: LocalizedError {
  case test
  var errorDescription: String? {
    return "Request failed, try again."
  }
}

var requestsCounter = 0

extension MockAPI {
  // An example of some custom token logic - for this demo we use a JSON struct that holds
  // a custom UUID and the count of elements to fetch in the current batch.
  static func requestBatchCustomToken(_ token: Data?) -> AnyPublisher<BatchesDataSource<String>.LoadResult, Error> {
    let serverToken: ServerToken? = token.map { try! JSONDecoder().decode(ServerToken.self, from: $0) }
    // Do network request, database lookup, etc. here
    return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        let currentBatchCount = serverToken?.count ?? 2
        let nextToken = ServerToken(id: UUID(), count: currentBatchCount * 2)
        let items = (0..<currentBatchCount).map { _ in UUID().uuidString }
        
        requestsCounter += 1
        guard requestsCounter.quotientAndRemainder(dividingBy: 4).remainder > 0 else {
          // Return a test error
          promise(.failure(APIError.test))
          return
        }
        
        guard currentBatchCount < 50 else {
          // No more items to fetch
          promise(.success(.completed))
          return
        }
        
        // Return the current batch items + the token to fetch the next batch.
        promise(.success(.itemsToken(items, nextToken: try! JSONEncoder().encode(nextToken))))
      }
    }.eraseToAnyPublisher()
  }
}

class CustomBatchesViewController: UIViewController {
  @IBOutlet var itemsLabel: UILabel!
  @IBOutlet var statusLabel: UILabel!
  @IBOutlet var loadNextButton: UIButton!
  @IBOutlet var resetButton: UIButton!
  
  var batcher: BatchesDataSource<String>!
  var subscriptions = [AnyCancellable]()
  
  let loadNextSubject = PassthroughSubject<Void, Never>()
  let resetSubject = PassthroughSubject<Void, Never>()
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let input = BatchesInput(
      reload: resetSubject.eraseToAnyPublisher(),
      loadNext: loadNextSubject.eraseToAnyPublisher()
    )
    
    batcher = BatchesDataSource<String>(
      items: ["Initial Element"],
      input: input,
      initialToken: nil,
      loadItemsWithToken: { token in
        return MockAPI.requestBatchCustomToken(token)
      })
    
    // Bind Items label
    batcher.output.$items
      .map { "\($0.count) items fetched" }
      .assign(to: \.text, on: itemsLabel)
      .store(in: &subscriptions)

    // Bind Status label
    Publishers.MergeMany([
      // Status: is loading
      batcher.output.$isLoading.filter { $0 }
        .map { _ in "Loading batch..." }.eraseToAnyPublisher(),
      
      // Status: is completed
      batcher.output.$isCompleted.filter { $0 }
        .map { _ in "Fetched all items available" }.eraseToAnyPublisher(),
      
      // Status: successfull fetch
      Publishers.CombineLatest3(batcher.output.$isLoading, batcher.output.$isCompleted, batcher.output.$error)
        .filter { !$0 && !$1 && $2 == nil}
        .map { _ in "Fetched succcessfully" }
        .eraseToAnyPublisher(),
      
      // Status: error
      batcher.output.$error
        .filter { $0 != nil }
        .map { $0?.localizedDescription }
        .eraseToAnyPublisher()
    ])
      .assign(to: \.text, on: statusLabel)
      .store(in: &subscriptions)
    
    // Bind Load next button alpha
    Publishers.CombineLatest(batcher.output.$isLoading, batcher.output.$isCompleted)
      .map { $0 || $1 ? 0.5 : 1.0 }
      .assign(to: \.alpha, on: loadNextButton)
      .store(in: &subscriptions)

    // Bind Load next is enabled
    Publishers.CombineLatest(batcher.output.$isLoading, batcher.output.$isCompleted)
      .map { !($0 || $1) }
      .assign(to: \.isEnabled, on: loadNextButton)
      .store(in: &subscriptions)
    
    // Bind Reset button
    batcher.output.$isLoading
      .map { !$0 }
      .assign(to: \.isEnabled, on: resetButton)
      .store(in: &subscriptions)
  }
  
  @IBAction func loadNext() {
    loadNextSubject.send()
  }
  
  @IBAction func reset() {
    resetSubject.send()
  }
}
