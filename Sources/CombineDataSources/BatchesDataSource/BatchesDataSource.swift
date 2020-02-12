//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

/*
 Data flow in BatchesDataSource:
 Dashed boxes represent the inputs provided to `BatchesDataSource.init(...)`.
 Single line boxes are the intermediate publishers.
 Double line boxes are the published outputs.
 
                                       ┌──────────────────────┐                   ╔════════════════════╗
               ┌──────────────────────▶│     itemsSubject     │──────────────────▶║   Output.$items    ║◀───┐
               │                       └──────────────────────┘                   ╚════════════════════╝    │
               │                                                                  ╔════════════════════╗    │
               │                       ┌──────────────────────┬──────────────────▶║ Output.$isLoading  ║    │
               │                       │                      │                   ╚════════════════════╝    │
               │                       │                      │                                             │
               │             ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
       ┌──────────────┐      │                   │  │                   │  │                   │  │                   │
 ┌─┬──▶│    reload    │──┬──▶│   batchRequest    │─▶│   batchResponse   │─▶│  successResponse  │─▶│      result       │
 │ │   └──────────────┘  │   │                   │  │                   │  │                   │  │                   │
 │ │                     │   └───────────────────┘  └───────────────────┘  └───────────────────┘  └───────────────────┘
 │ │             ┌──────────────┐      ▲                      │                      │                      │
 │ │             │   loadNext   │      └───────┐              │                      │                      │
 │ │             └──────────────┘              │              │                ┌─────┘                      │
 │ │                     ▲                     │              │                │                            │
 │ │                     │          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─     │                │  ╔════════════════════╗    │
 │ │  ┌ ─ ─ ─ ─ ─ ─ ─    │             loadNextBatch()   │    │                └─▶║Output.$isCompleted ║    │
 │ └──  initialToken │   │          └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─     │                   ╚════════════════════╝    │
 │    └ ─ ─ ─ ─ ─ ─ ─    │                                    │                   ╔════════════════════╗    │
 │                       │                                    └──────────────────▶║   Output.$error    ║    │
 │  ┌ ─ ─ ─ ─ ─ ─ ─      │                                                        ╚════════════════════╝    │
 └──     items     │     │                             ┌──────────────────┐                                 │
    └ ─ ─ ─ ─ ─ ─ ─      └─────────────────────────────│      token       │◀────────────────────────────────┘
                                                       └──────────────────┘
 */

import Foundation
import Combine

/// Batches source input. Provides two publishers to control requesting the next batch
/// of items and resetting the items collection.
public struct BatchesInput {
    public init(reload: AnyPublisher<Void, Never>? = nil, loadNext: AnyPublisher<Void, Never>) {
        self.reload = reload ?? Empty<Void, Never>().eraseToAnyPublisher()
        self.loadNext = loadNext
    }
    
    /// Resets the list and loads the initial list of items.
    public let reload: AnyPublisher<Void, Never>
    
    /// Loads the next batch of items.
    public let loadNext: AnyPublisher<Void, Never>
}

/// Manages a list of items in batches or pages.
public struct BatchesDataSource<Element> {
    internal let input: BatchesInput
    
    public class Output {
        /// Is the data source currently fetching a batch of items.
        @Published public var isLoading = false
        
        /// Is the data source loaded all available items.
        @Published public var isCompleted = false
        
        /// The list of items fetched so far.
        @Published public var items = [Element]()
        
        /// The last error while fetching a batch of items.
        @Published public var error: Error? = nil
    }
    
    /// The current output of the data source.
    public let output = Output()
    
    private var subscriptions = [AnyCancellable]()
    
    /// The result of loading of a batch of items.
    public enum LoadResult {
        /// A batch of `Element` items to use with pages.
        case items([Element])
        
        /// A batch of `Element` items and a token to provide
        /// to the loader in order to fetch the next batch.
        case itemsToken([Element], nextToken: Data?)
        
        /// No more items available to fetch.
        case completed
    }
    
    enum ResponseResult {
        case result((token: Token, result: BatchesDataSource<Element>.LoadResult))
        case error(Error)
    }
    
    enum Token {
        case int(Int)
        case data(Data?)
    }
    
    private init(items: [Element] = [], input: BatchesInput, initial: Token, loadNextCallback: @escaping (Token) -> AnyPublisher<LoadResult, Error>) {
        let itemsSubject = CurrentValueSubject<[Element], Never>(items)
        let token = CurrentValueSubject<Token, Never>(initial)
        
        self.input = input
        let output = self.output
        
        input.reload
            .map { _ in items }
            .append(Empty(completeImmediately: false))
            .subscribe(itemsSubject)
            .store(in: &subscriptions)
        
        let loadNext = input.loadNext
            .map { token.value }
        
        let batchRequest = loadNext
            .merge(with: input.reload.prepend(()).map { initial })
            .eraseToAnyPublisher()
        
        // TODO: avoid having extra subject when `shareReplay()` is introduced.
        let batchResponse = PassthroughSubject<ResponseResult, Never>()
        
        batchResponse
            .map { result -> Error? in
                switch result {
                case .error(let error): return error
                default: return nil
                }
        }
        .assign(to: \Output.error, on: output)
        .store(in: &subscriptions)
        
        // Bind `Output.isLoading`
        Publishers.Merge(batchRequest.map { _ in true }, batchResponse.map { _ in false })
            .assign(to: \Output.isLoading, on: output)
            .store(in: &subscriptions)
        
        let successResponse = batchResponse
            .compactMap { result -> (token: Token, result: BatchesDataSource<Element>.LoadResult)? in
                switch result {
                case .result(let result): return result
                default: return nil
                }
        }
        .share()
        
        // Bind `Output.isCompleted`
        successResponse
            .map { tuple -> Bool in
                switch tuple.result {
                case .completed: return true
                default: return false
                }
        }
        .assign(to: \Output.isCompleted, on: output)
        .store(in: &subscriptions)
        
        let result = successResponse
            .compactMap { tuple -> (token: Token, items: [Element], nextToken: Token)? in
                switch tuple.result {
                case .completed:
                    return nil
                case .items(let elements):
                    // Fix incremeneting page number
                    guard case Token.int(let currentPage) = tuple.token else { fatalError() }
                    return (token: tuple.token, items: elements, nextToken: .int(currentPage+1))
                case .itemsToken(let elements, let nextToken):
                    return (token: tuple.token, items: elements, nextToken: .data(nextToken))
                }
        }
        .share()
        
        // Bind `token`
        result
            .map { $0.nextToken }
            .subscribe(token)
            .store(in: &subscriptions)
        
        // Bind `items`
        result
            .map {
                // TODO: Solve for `withLatestFrom(_)`
                let currentItems = itemsSubject.value
                return currentItems + $0.items
        }
        .subscribe(itemsSubject)
        .store(in: &subscriptions)
        
        // Bind `Output.items`
        itemsSubject
            .assign(to: \Output.items, on: output)
            .store(in: &subscriptions)
        
        batchRequest
            .flatMap { token in
                return loadNextCallback(token)
                    .map { result -> ResponseResult in
                        return .result((token: token, result: result))
                }
                .catch { error in
                    Just(ResponseResult.error(error))
                }
                .append(Empty(completeImmediately: true))
        }
        .sink(receiveValue: batchResponse.send)
        .store(in: &subscriptions)
        
    }
    
    /// Initializes a list data source using a token to fetch batches of items.
    /// - Parameter items: initial list of items.
    /// - Parameter input: the input to control the data source.
    /// - Parameter initialToken: the token to use to fetch the first batch.
    /// - Parameter loadItemsWithToken: a `(Data?) -> (Publisher<LoadResult, Error>)` closure that fetches a batch of items and returns the items fetched
    ///   plus a token to use for the next batch. The token can be an alphanumerical id, a URL, or another type of token.
    /// - Todo: if `withLatestFrom` is introduced, use it instead of grabbing the latest value unsafely.
    public init(items: [Element] = [], input: BatchesInput, initialToken: Data?, loadItemsWithToken: @escaping (Data?) -> AnyPublisher<LoadResult, Error>) {
        self.init(items: items, input: input, initial: Token.data(initialToken), loadNextCallback: { token -> AnyPublisher<LoadResult, Error> in
            switch token {
            case .data(let data):
                return loadItemsWithToken(data)
            default: fatalError()
            }
        })
    }
    
    /// Initialiazes a list data source of items batched in numbered pages.
    /// - Parameter items: initial list of items.
    /// - Parameter input: the input to control the data source.
    /// - Parameter initialPage: the page number to use for the first load of items.
    /// - Parameter loadPage: a `(Int) -> (Publisher<LoadResult, Error>)` closure that fetches a batch of items.
    /// - Todo: if `withLatestFrom` is introduced, use it instead of grabbing the latest value unsafely.
    public init(items: [Element] = [], input: BatchesInput, initialPage: Int = 0, loadPage: @escaping (Int) -> AnyPublisher<LoadResult, Error>) {
        self.init(items: items, input: input, initial: Token.int(initialPage), loadNextCallback: { page -> AnyPublisher<LoadResult, Error> in
            switch page {
            case .int(let page):
                return loadPage(page)
            default: fatalError()
            }
        })
    }
}

fileprivate var uuids = [String: Int]()

extension Publisher {
    public func assertMaxSubscriptions(_ max: Int, file: StaticString = #file, line: UInt = #line) -> AnyPublisher<Output, Failure> {
        let uuid = "\(file):\(line)"
        
        return handleEvents(receiveSubscription: { _ in
            let count = uuids[uuid] ?? 0
            guard count < max else {
                assert(false, "Publisher subscribed more than \(max) times.")
                return
            }
            uuids[uuid] = count + 1
        }).eraseToAnyPublisher()
    }
}
