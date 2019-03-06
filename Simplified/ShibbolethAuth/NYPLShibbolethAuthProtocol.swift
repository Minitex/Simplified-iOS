//
//  NYPLShibbolethAuthProtocol.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/27/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

@objc public protocol NYPLShibbolethAuthDelegate: class {
  // Bool always returns a login status, where
  // true means logged in, false means signed out
  func getLoginStatus() -> Bool
  func toggleLogin() -> Bool

  // returns an optional error, if any
  func saveLoginCredentials() -> Error?
  func removeLoginCredentials() -> Error?
}
