//
//  NYPLPDFBookMinitexDelegate.swift
//  SimplyE
//
//  Created by Vui Nguyen on 5/23/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation
import MinitexPDFProtocols

class NYPLBookMinitexDelegate: MinitexPDFViewControllerDelegate {
  func userDidNavigate(page: Int) {
    print("userDidNavigate called")
  }

  func saveBookmarks(pageNumbers: [UInt]) {
    print("saveBookmarks called")
  }

  func saveAnnotations(annotations: [MinitexPDFAnnotation]) {
    print("saveAnnotations called")
  }
  

}
