//
//  NYPLShibbolethMockData.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/28/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

@objc class NYPLShibbolethMockData: NSObject, NYPLShibbolethAuthDelegate {



  let loginStatusKey = "loginStatus"

  func getLoginStatus() -> Bool {
    var login = false
    if (UserDefaults.standard.object(forKey: loginStatusKey) != nil){
      print("loginStatus is \(UserDefaults.standard.bool(forKey: loginStatusKey))")
    } else {
      UserDefaults.standard.set(false, forKey: loginStatusKey)
      print("loginStatus has just been set to \(UserDefaults.standard.bool(forKey: loginStatusKey))")
      UserDefaults.standard.synchronize()
    }

    login = UserDefaults.standard.bool(forKey: loginStatusKey)
    return login
  }


  func toggleLogin() -> Bool {
    var loginStatus = false
    if (UserDefaults.standard.object(forKey: loginStatusKey) != nil){
      print("loginStatus is \(UserDefaults.standard.bool(forKey: loginStatusKey))")

      loginStatus = UserDefaults.standard.bool(forKey: loginStatusKey)
      UserDefaults.standard.set(!loginStatus, forKey: loginStatusKey)
    }
    return !loginStatus
  }

}
