//
//  NYPLPDFBookNavigationController.swift
//  SimplyE
//
//  Created by Vui Nguyen on 5/23/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation
import MinitexPDFProtocols

class NYPLPDFBookNavigationController: UINavigationController {
  convenience init() {
    let minitexDelegate = NYPLPDFBookMinitexDelegate()
    self.init(rootViewController: NYPLPDFBookController.getPDFViewController(delegate: minitexDelegate) as! UIViewController)
    self.tabBarItem.image = UIImage(named: "Clock")
    super.title = "PDF"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
  }

  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
  }

  override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
    fatalError("navigationBarClass:) has not been implemented")
  }

}
