//
//  NYPLShibbolethAuthProtocol.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/27/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

@objc public protocol NYPLShibbolethAuthDelegate: class {
  //func saveShibbCredentials()
  func getLoginStatus() -> Bool
  func toggleLogin() -> Bool
}
