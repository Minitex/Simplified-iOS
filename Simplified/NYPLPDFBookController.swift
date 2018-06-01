//
//  NYPLPDFBookController.swift
//  SimplyE
//
//  Created by Vui Nguyen on 5/21/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation
import MinitexPDFProtocols

class NYPLPDFBookController: NSObject {
  static func getPDFViewController(delegate: MinitexPDFViewControllerDelegate, fileURL: URL) -> MinitexPDFViewController? {

    print("instantiate NYPLPDFBookController")

    let pdfDictionary: [String: Any] = [
      "PSPDFKitLicense": APIKeys.PDFLicenseKey,
      "delegate": delegate,
      "documentURL": fileURL,
      "openToPage": UInt(0),
      "bookmarks": [],
      "annotations": []
    ]

    // we should do some verification on types of dictionary so it doesn't fail
    let pdfViewController = MinitexPDFViewControllerFactory.createPDFViewController(dictionary: pdfDictionary)


    if pdfViewController != nil {
      return pdfViewController
    } else {
      print("PDF module does not exist")
      return nil
    }
  }

  static func getPDFViewController(delegate: MinitexPDFViewControllerDelegate) -> MinitexPDFViewController?  {
    let documentName = "DataModeling"
    guard let fileURL: URL = Bundle.main.url(forResource: documentName, withExtension: "pdf") else {
      return nil
    }
    return getPDFViewController(delegate: delegate, fileURL: fileURL)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
