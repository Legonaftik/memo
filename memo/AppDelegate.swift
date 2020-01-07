//
//  Created by Vladimir Pavlov on 04/10/2017.
//  Copyright © 2017 Vladimir Pavlov. All rights reserved.
//

import UIKit
import Rswift

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // TODO: Move into tests instead
        #if DEBUG
        do {
          try R.validate()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        #endif

        return true
    }
}
