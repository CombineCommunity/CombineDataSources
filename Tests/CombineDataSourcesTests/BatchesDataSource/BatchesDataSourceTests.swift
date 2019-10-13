import Foundation
import Combine
import XCTest

@testable import CombineDataSources

final class BatchesDataSourceTests: XCTestCase {
  var input: BatchesInput {
    BatchesInput(loadNext: PassthroughSubject<Void, Never>().eraseToAnyPublisher())
  }
  
  var inputControls: (input: BatchesInput, reload: PassthroughSubject<Void, Never>, loadNext: PassthroughSubject<Void, Never>) {
    let reload = PassthroughSubject<Void, Never>()
    let loadNext = PassthroughSubject<Void, Never>()
    let input = BatchesInput(reload: reload.eraseToAnyPublisher(), loadNext: loadNext.eraseToAnyPublisher())
    return (input: input, reload: reload, loadNext: loadNext)
  }
  
  func testInitialState() {
    let batcher = BatchesDataSource<String>(input: input) { page in
      return Empty<BatchesDataSource<String>.LoadResult, Error>().eraseToAnyPublisher()
    }
    
    XCTAssertEqual(batcher.output.isLoading, true)
    XCTAssertEqual(batcher.output.isCompleted, false)
    XCTAssertTrue(batcher.output.items.isEmpty)
    XCTAssertNil(batcher.output.error)
  }
  
  func testInitialItems() {
    let testStrings = ["test1", "test2"]
    let batcher = BatchesDataSource<String>(items: testStrings, input: input) { page in
      return Empty<BatchesDataSource<String>.LoadResult, Error>().eraseToAnyPublisher()
    }
    
    XCTAssertEqual(batcher.output.items, testStrings)
  }
  
  func testInitialLoadSynchronous() {
    let testStrings = ["test1", "test2"]
    var subscriptions = [AnyCancellable]()
    
    let batcher = BatchesDataSource<String>(items: testStrings, input: input) { page in
      return Just<BatchesDataSource<String>.LoadResult>(.items(["test3"]))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$items
      .prefix(1)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([testStrings + ["test3"]], values)
      }
      .store(in: &subscriptions)
    
    wait(for: [controlEvent], timeout: 1)
  }

  func testInitialLoadAsynchronous() {
    let testStrings = ["test1", "test2"]
    var subscriptions = [AnyCancellable]()
    
    let batcher = BatchesDataSource<String>(items: testStrings, input: input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          promise(.success(.items(["test3"])))
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$items
      .prefix(2)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([testStrings, testStrings + ["test3"]], values)
      }
      .store(in: &subscriptions)
    
    wait(for: [controlEvent], timeout: 1)
  }

  func testLoadNext() {
    let testStrings = ["test1", "test2"]
    var subscriptions = [AnyCancellable]()
    
    let inputControls = self.inputControls
    
    let batcher = BatchesDataSource<String>(items: testStrings, input: inputControls.input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          promise(.success(.items(["test3"])))
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$items
      .dropFirst(2)
      .prefix(2)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([
          testStrings + ["test3", "test3"],
          testStrings + ["test3", "test3", "test3"]
        ], values)
      }
      .store(in: &subscriptions)

    DispatchQueue.global().async {
      inputControls.loadNext.send()
    }
    DispatchQueue.global().async {
      inputControls.loadNext.send()
    }

    wait(for: [controlEvent], timeout: 1)
  }

  func testReload() {
    let testStrings = ["test1", "test2"]
    var subscriptions = [AnyCancellable]()
    
    let inputControls = self.inputControls
    
    let batcher = BatchesDataSource<String>(items: testStrings, input: inputControls.input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          promise(.success(.items(["test3"])))
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$items
      .dropFirst(2)
      .prefix(2)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([
          testStrings + ["test3"],
          testStrings + ["test3", "test3"]
        ], values)
      }
      .store(in: &subscriptions)

    DispatchQueue.global().async {
      inputControls.reload.send()
      inputControls.loadNext.send()
    }

    wait(for: [controlEvent], timeout: 1)
  }

  func testIsCompleted() {
    var subscriptions = [AnyCancellable]()
    let inputControls = self.inputControls

    var shouldComplete = false
    
    let batcher = BatchesDataSource<String>(input: inputControls.input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          if shouldComplete {
            promise(.success(.items(["test3"])))
          } else {
            promise(.success(.completed))
          }
          shouldComplete.toggle()
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$isCompleted
      .prefix(3)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([
          false, true, false
        ], values)
      }
      .store(in: &subscriptions)

    DispatchQueue.global().async {
      inputControls.loadNext.send()
      inputControls.reload.send()
    }

    wait(for: [controlEvent], timeout: 1)
  }

  func testIsLoading() {
    var subscriptions = [AnyCancellable]()
    let inputControls = self.inputControls

    let batcher = BatchesDataSource<String>(input: inputControls.input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          promise(.success(.items(["test3"])))
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$isLoading
      .prefix(4)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertEqual([
          true, false, true, false
        ], values)
      }
      .store(in: &subscriptions)

    DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) {
      inputControls.loadNext.send()
    }

    wait(for: [controlEvent], timeout: 1)
  }

  func testError() {
    var subscriptions = [AnyCancellable]()
    let inputControls = self.inputControls

    var shouldError = false
    
    let batcher = BatchesDataSource<String>(input: inputControls.input) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          if shouldError {
            promise(.success(.items(["test3"])))
          } else {
            promise(.failure(TestError.test))
          }
          shouldError.toggle()
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")

    batcher.output.$error
      .prefix(4)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        XCTAssertNil(values[0])
        XCTAssertNotNil(values[1] as? TestError)
        XCTAssertNil(values[2])
        XCTAssertNotNil(values[3] as? TestError)
      }
      .store(in: &subscriptions)

    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      inputControls.loadNext.send()
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
      inputControls.loadNext.send()
    }

    wait(for: [controlEvent], timeout: 1)
  }
  
  func _mergeStrategy(initial: [String], output: String, strategy: BatchesDataSource<String>.MergeStrategy) -> [[String]] {
    let testStrings = ["test1", "test2"]
    var subscriptions = [AnyCancellable]()
    
    let inputControls = self.inputControls
    
    let batcher = BatchesDataSource<String>(items: testStrings, input: inputControls.input, merge: strategy) { page in
      return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
        DispatchQueue.main.async {
          promise(.success(.items(["test3"])))
        }
      }.eraseToAnyPublisher()
    }
    
    let controlEvent = expectation(description: "Wait for control event")
    var result = [[String]]()
    
    batcher.output.$items
      .prefix(2)
      .collect()
      .sink(receiveCompletion: { _ in
        controlEvent.fulfill()
      }) { values in
        result = values
      }
      .store(in: &subscriptions)

    DispatchQueue.global().async {
      inputControls.loadNext.send()
    }

    wait(for: [controlEvent], timeout: 1)
    
    return result
  }
  
  func testMergeStrategyDefault() {
    let result = _mergeStrategy(initial: ["test1", "test2"], output: "test3", strategy: .default)
    XCTAssertEqual(result, [
      ["test1", "test2"],
      ["test1", "test2", "test3"]
    ])
  }

  func testMergeStrategyAppend() {
    let result = _mergeStrategy(initial: ["test1", "test2"], output: "test3", strategy: .append)
    XCTAssertEqual(result, [
      ["test1", "test2"],
      ["test1", "test2", "test3"]
    ])
  }

  func testMergeStrategyPrepend() {
    let result = _mergeStrategy(initial: ["test1", "test2"], output: "test3", strategy: .prepend)
    XCTAssertEqual(result, [
      ["test1", "test2"],
      ["test3", "test1", "test2"]
    ])
  }

  func testMergeStrategyCustom() {
    let result = _mergeStrategy(initial: ["test1", "test2"], output: "test3", strategy: .reduce({ (current, new) -> [String] in
      return new
    }))
    XCTAssertEqual(result, [
      ["test1", "test2"],
      ["test3"]
    ])
  }
}
