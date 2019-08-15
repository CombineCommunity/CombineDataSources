//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import Foundation
import Combine

public extension Publisher where Failure == Never {
  func subscribe<S: Subscriber>(retaining subscriber: S) -> AnyCancellable
    where S.Failure == Never, S.Input == Output {
    
    sink(receiveCompletion: { (completion) in
      subscriber.receive(completion: completion)
    }) { (value) in
      _ = subscriber.receive(value)
    }
  }
}
