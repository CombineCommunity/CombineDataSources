//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

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
    /// A batch of `Element` items.
    case items([Element])
    
    /// A batch of `Element` items and a token to provide
    /// to the loader in order to fetch the next batch.
    case itemsToken([Element], nextToken: Data)
    
    /// No more items available to fetch.
    case completed
  }
  
  enum ResponseResult {
    case result((token: Data?, result: BatchesDataSource<Element>.LoadResult))
    case error(Error)
  }
  
  /// Initializes a list data source using a token to fetch batches of items.
  /// - Parameter items: initial list of items.
  /// - Parameter input: the input to control the data source.
  /// - Parameter initialToken: the token to use to fetch the first batch.
  /// - Parameter loadItemsWithToken: a `(Data?) -> (Publisher<LoadResult, Error>)` closure that fetches a batch of items and returns the items fetched
  ///   plus a token to use for the next batch. The token can be an alphanumerical id, a URL, or another type of token.
  /// - Todo: if `withLatestFrom` is introduced, use it instead of grabbing the latest value unsafely.
  public init(items: [Element] = [], input: BatchesInput, initialToken: Data?, loadItemsWithToken: @escaping (Data?) -> AnyPublisher<LoadResult, Error>) {
    let itemsSubject = CurrentValueSubject<[Element], Never>(items)
    let token = CurrentValueSubject<Data?, Never>(initialToken)

    self.input = input
    let output = self.output
    
    let reload = input.reload
      .share()

    reload
      .map { _ in
        return items
      }
      .subscribe(itemsSubject)
      .store(in: &subscriptions)
    
    let loadNext = input.loadNext
      .map { token.value }
    
    let batchRequest = loadNext.merge(with: reload.map { initialToken })
      .share()
      .prepend(initialToken)
    
    let batchResponse = batchRequest
      .flatMap { token in
        return loadItemsWithToken(token)
          .map { result -> ResponseResult in
            return .result((token: token, result: result))
          }
          .catch { error in
            Just(ResponseResult.error(error))
          }
      }
      .eraseToAnyPublisher()
      .share()
    
    batchResponse
      .compactMap { result -> Error? in
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
      .compactMap { result -> (token: Data?, result: BatchesDataSource<Element>.LoadResult)? in
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
      .compactMap { tuple -> (token: Data?, items: [Element], nextToken: Data?)? in
        switch tuple.result {
        case .completed: return nil
        case .itemsToken(let elements, let nextToken): return (token: tuple.token, items: elements, nextToken: nextToken)
        default: fatalError()
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
        let currentItems = itemsSubject.value
        return currentItems + $0.items
      }
      .subscribe(itemsSubject)
      .store(in: &subscriptions)

    // Bind `Output.items`
    itemsSubject
      .assign(to: \Output.items, on: output)
      .store(in: &subscriptions)
  }

  /// Initialiazes a list data source of items batched in numbered pages.
  /// - Parameter items: initial list of items.
  /// - Parameter input: the input to control the data source.
  /// - Parameter initialPage: the page number to use for the first load of items.
  /// - Parameter loadPage: a `(Int) -> (Publisher<LoadResult, Error>)` closure that fetches a batch of items.
  /// - Todo: if `withLatestFrom` is introduced, use it instead of grabbing the latest value unsafely.
  public init(items: [Element] = [], input: BatchesInput, initialPage: Int = 0, loadPage: @escaping (Int) -> AnyPublisher<LoadResult, Error>) {
    let itemsSubject = CurrentValueSubject<[Element], Never>(items)
    let currentPage = CurrentValueSubject<Int, Never>(initialPage)
    
    self.input = input
    let output = self.output
    
    let reload = input.reload
      .share()
    
    reload
      .map { _ in
        return items
      }
      .subscribe(itemsSubject)
      .store(in: &subscriptions)

    let loadNext = input.loadNext
      .map { currentPage.value + 1 }
    
    let pageRequest = loadNext.merge(with: reload.map { -1 })
      .share()
      .prepend(1)

    // TODO: Add the response error handling like for batches
    
    // Bind `Output.isLoading = true`
    pageRequest
      .map { _ in true }
      .assign(to: \Output.isLoading, on: output)
      .store(in: &subscriptions)
    
    let pageResponse = pageRequest
      .flatMap { page in
        return loadPage(page == -1 ? 1 : page)
          .handleEvents(receiveOutput: { _ in
            output.error = nil
          },
          receiveCompletion: { completion in
            if case Subscribers.Completion.failure(let error) = completion {
              output.error = error
            } else {
              output.error = nil
            }
          })
          .catch { _ in
            return Empty()
          }
          .map { (pageNumber: page, result: $0) }
      }
      .eraseToAnyPublisher()
      .share()

    // Bind `Output.isLoading = false`
    Publishers.Merge(pageRequest.map { _ in true }, pageResponse.map { _ in false })
      .assign(to: \Output.isLoading, on: output)
      .store(in: &subscriptions)

    // Bind `Output.isCompleted`
    pageResponse
      .map { tuple -> Bool in
        switch tuple.result {
        case .completed: return true
        default: return false
        }
      }
      .assign(to: \Output.isCompleted, on: output)
      .store(in: &subscriptions)
    
    // Bind `items`
    pageResponse
      .compactMap { tuple -> (pageNumber: Int, items: [Element])? in
        switch tuple.result {
        case .completed: return nil
        case .items(let elements): return (pageNumber: tuple.pageNumber, items: elements)
        default: fatalError()
        }
      }
      .map {
        let currentItems = itemsSubject.value
        return currentItems + $0.items
      }
      .subscribe(itemsSubject)
      .store(in: &subscriptions)
    
    // Bind `currentPage`
    pageResponse
      .map { $0.pageNumber }
      .subscribe(currentPage)
      .store(in: &subscriptions)
    
    // Bind `Output.items`
    itemsSubject
      .assign(to: \Output.items, on: output)
      .store(in: &subscriptions)
  }
}

