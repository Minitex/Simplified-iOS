//
//  NYPLShibbolethLoginSignOutTableViewCell.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/21/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import UIKit
import PureLayout

@objc class NYPLShibbolethLoginSignOutTableViewCell: UITableViewCell {
  
  @IBOutlet weak var loginSignOutTextField: UITextField!
  let verticalMarginPadding = 2.0
  let signOut = "Sign Out"
  let login = "Login"
  var delegate: NYPLShibbolethAuthDelegate?

  enum LoginSignoutError: Error {
    case noDelegateError
    case loginError
    case signOutError
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    selectionStyle = UITableViewCellSelectionStyle.none
    layoutTextField()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  func layoutTextField() {
    loginSignOutTextField.font = UIFont.customFont(forTextStyle: UIFontTextStyle.body)
    loginSignOutTextField.text = login
    loginSignOutTextField.textAlignment = .center
    loginSignOutTextField.preservesSuperviewLayoutMargins = true
    loginSignOutTextField.autoPinEdge(toSuperviewMargin: ALEdge.right)
    loginSignOutTextField.autoPinEdge(toSuperviewMargin: ALEdge.left)

    // PureLayout
    loginSignOutTextField.autoConstrainAttribute(ALAttribute.top, to: ALAttribute.marginTop, of: loginSignOutTextField.superview!, withOffset: CGFloat(verticalMarginPadding))
    loginSignOutTextField.autoConstrainAttribute(ALAttribute.bottom, to: ALAttribute.marginBottom, of: loginSignOutTextField.superview!, withOffset: CGFloat(-verticalMarginPadding))
  }

  func setButtonText(loginStatus: Bool) {
    loginSignOutTextField.text = (loginStatus == false) ? login : signOut
  }

  func shibbolethLogin() -> Error? {
    print("shibbolethLogin called")
    guard delegate != nil else {
      return LoginSignoutError.noDelegateError
    }

    guard delegate?.saveLoginCredentials() == nil else {
      return LoginSignoutError.loginError
    }
    return nil
  }

  func shibbolethSignOut() -> Error? {
    print("shibbolethLogout called")
    guard delegate != nil else {
      return LoginSignoutError.noDelegateError
    }

    guard delegate?.removeLoginCredentials() == nil else {
      return LoginSignoutError.signOutError
    }
    return nil
  }
}
