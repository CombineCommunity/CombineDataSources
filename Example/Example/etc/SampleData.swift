
import Foundation
import Combine
import CombineDataSources

enum SampleDataType {
  case pages, batches
}

func sampleData(_ type: SampleDataType) -> AnyPublisher<BatchesDataSource<String>.LoadResult, Error> {
  return Future<BatchesDataSource<String>.LoadResult, Error> { promise in
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        switch type {
        case .pages:
          promise(.success(BatchesDataSource.LoadResult.items((0..<20).map { _ in UUID().uuidString })))
        
        case .batches:
          promise(.success(BatchesDataSource.LoadResult.itemsToken((0..<20).map { _ in UUID().uuidString },
            nextToken: "nextTokenFromServer".data(using: .utf8)!)
          ))
        }
    }
  }.eraseToAnyPublisher()
}
