//
//  For credits and licence check the LICENSE file included in this package.
//  (c) CombineOpenSource, Created by Marin Todorov.
//

import UIKit
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var subscriptions = [AnyCancellable]()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let publisher = Future<String, Never> { promise in
      print("request network data")
      
      DispatchQueue.main.async {
        promise(.success("JSON"))
      }
    }
    .eraseToAnyPublisher()
    .assertMaxSubscriptions(1)
    .share()

    publisher
    .sink { print($0) }
    .store(in: &subscriptions)

    publisher
    .sink { print($0) }
    .store(in: &subscriptions)
    
    return true
  }

  // MARK: UISceneSession Lifecycle
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
