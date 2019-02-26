//
//  NYPLShibbolethLoginSignOutTableViewCell.swift
//  SimplyE
//
//  Created by Vui Nguyen on 2/21/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import UIKit
import PureLayout

class NYPLShibbolethLoginSignOutTableViewCell: UITableViewCell {
  
  @IBOutlet weak var loginSignOutTextField: UITextField!
  let verticalMarginPadding = 2.0
  
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
    loginSignOutTextField.text = "Sign Out"
    //loginSignOutTextField.textColor = NYPLConfiguration.mainColor()
    loginSignOutTextField.textColor = .blue
    loginSignOutTextField.textAlignment = .center
    loginSignOutTextField.preservesSuperviewLayoutMargins = true
    loginSignOutTextField.autoPinEdge(toSuperviewMargin: ALEdge.right)
    loginSignOutTextField.autoPinEdge(toSuperviewMargin: ALEdge.left)

    // PureLayout
    loginSignOutTextField.autoConstrainAttribute(ALAttribute.top, to: ALAttribute.marginTop, of: loginSignOutTextField.superview!, withOffset: CGFloat(verticalMarginPadding))
    loginSignOutTextField.autoConstrainAttribute(ALAttribute.bottom, to: ALAttribute.marginBottom, of: loginSignOutTextField.superview!, withOffset: CGFloat(-verticalMarginPadding))
  }
}
