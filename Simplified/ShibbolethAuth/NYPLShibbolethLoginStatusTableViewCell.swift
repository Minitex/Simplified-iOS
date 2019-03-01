//
//  NYPLShibbolethLoginStatusTableViewCell.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/21/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import UIKit
import PureLayout

class NYPLShibbolethLoginStatusTableViewCell: UITableViewCell {

  @IBOutlet weak var statusTextField: UITextField!
  let verticalMarginPadding = 2.0
  let loggedIn = "Logged in as Columbia User"
  let signedOut = "Signed Out"
  
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
    statusTextField.font = UIFont.customFont(forTextStyle: UIFontTextStyle.body)
    statusTextField.text = signedOut
    statusTextField.textAlignment = .center
    statusTextField.preservesSuperviewLayoutMargins = true
    statusTextField.autoPinEdge(toSuperviewMargin: ALEdge.right)
    statusTextField.autoPinEdge(toSuperviewMargin: ALEdge.left)

    // PureLayout
    statusTextField.autoConstrainAttribute(ALAttribute.top, to: ALAttribute.marginTop, of: statusTextField.superview!, withOffset: CGFloat(verticalMarginPadding))
    statusTextField.autoConstrainAttribute(ALAttribute.bottom, to: ALAttribute.marginBottom, of: statusTextField.superview!, withOffset: CGFloat(-verticalMarginPadding))
  }

  func setLoginStatus(loginStatus: Bool) {
    statusTextField.text = (loginStatus == false) ? signedOut : loggedIn
  }
}
