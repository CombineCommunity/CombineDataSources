//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import Foundation
import Combine

public typealias Binding = Subscriber

public extension Publisher where Failure == Never {
    func bind<B: Binding>(subscriber: B) -> AnyCancellable
        where B.Failure == Never, B.Input == Output {
            
            handleEvents(receiveSubscription: { subscription in
                subscriber.receive(subscription: subscription)
            })
                .sink { value in
                    _ = subscriber.receive(value)
            }
    }
}
