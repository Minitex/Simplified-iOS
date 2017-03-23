//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit

final class NYPLAnnotations: NSObject {
  
  class func postLastRead(_ book:NYPLBook, cfi:NSString)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      let parameters = [
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "Annotation",
        "motivation": "http://librarysimplified.org/terms/annotation/idling",
        "target":[
          "source":  book.identifier,
          "selector": [
            "type": "oa:FragmentSelector",
            "value": cfi
          ]
        ],
        "body": [
          "http://librarysimplified.org/terms/time" : NSDate().rfc3339String(),
          "http://librarysimplified.org/terms/device" : NYPLAccount.shared().deviceID
        ]
        ] as [String : Any]
      
      let url = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
      
      if let url = url {
        
        print("NYPLAnnotations::postLastRead, book is: \(book)")
        print("NYPLAnnotations::postLastRead, url is: \(url)")
        print("NYPLAnnotations::postLastRead, parameters is: \(parameters)")
        print("NYPLAnnotations::postLastRead, NYPLAnnotations.headers is: \(NYPLAnnotations.headers)")
        
        postJSONRequest(book, url, parameters, NYPLAnnotations.headers)
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
    
  class func postBookmark(_ book:NYPLBook, cfi:NSString)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      let parameters = [
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "Annotation",
        "motivation": "http://www.w3.org/ns/oa#bookmarking",
        "target":[
            "source":  book.identifier,
            "selector": [
              "type": "oa:FragmentSelector",
              "value": cfi
            ]
        ],
        "body": [
            "http://librarysimplified.org/terms/time" : NSDate().rfc3339String(),
            "http://librarysimplified.org/terms/device" : NYPLAccount.shared().deviceID
        ]
    ] as [String : Any]
    
    let url = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
    
    if let url = url {
    
        print("NYPLAnnotations::postBookmark, book is: \(book)")
        print("NYPLAnnotations::postBookmark, url is: \(url)")
        print("NYPLAnnotations::postBookmark, parameters is: \(parameters)")
        print("NYPLAnnotations::postBookmark, NYPLAnnotations.headers is: \(NYPLAnnotations.headers)")
    
        postJSONRequest(book, url, parameters, NYPLAnnotations.headers)
      } else {
         Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
    
  class func getBookmarks(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ())
  {
    syncLastRead(book, completionHandler: completionHandler)
  }
    
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ())
  {
    syncLastRead(book, completionHandler: completionHandler)
  }
  
  private class func postJSONRequest(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
  {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    
    if let headers = headers {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let response = response as? HTTPURLResponse {
        print("NYPLAnnotations::postJSONRequest, response.statusCode is \(response.statusCode)")
        
        if response.statusCode == 200 {
          debugPrint(#file, "Posted Last-Read \(((parameters["target"] as! [String:Any])["selector"] as! [String:Any])["value"] as! String)")
        }
      } else {
        guard let error = error as? NSError else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(book, url, parameters)
        }
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  private class func addToOfflineQueue(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any])
  {
    let libraryID = AccountsManager.shared.currentAccount.id
    let parameterData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    NetworkQueue.addRequest(libraryID, book.identifier, url, .POST, parameterData, headers)
  }
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {
       
    if (NYPLAccount.shared().hasBarcodeAndPIN() && book.annotationsURL != nil)
    {
      var request = URLRequest.init(url: book.annotationsURL,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 30)
      request.httpMethod = "GET"
      
      for (headerKey, headerValue) in NYPLAnnotations.headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
      
      let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if error != nil {
          completionHandler(nil)
          return
        } else {
          
          guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any] else {
            Log.error(#file, "JSON could not be created from data.")
            completionHandler(nil)
            return
          }
          
          guard let total:Int = json["total"] as? Int else {
            completionHandler(nil)
            return
          }
          
          if total > 0
          {
            
            guard let first = json["first"] as? [String:AnyObject], let items = first["items"] as? [AnyObject] else {
              completionHandler(nil)
              return
            }
            
            for item in items
            {
              
              guard let target = item["target"] as? [String:AnyObject], let source = target["source"] as? String else {
                completionHandler(nil)
                return
              }
              
              if source == book.identifier
              {
                
                guard let selector = target["selector"] as? [String:AnyObject], let serverCFI = selector["value"] as? String else {
                  completionHandler(nil)
                  return
                }
                
                var responseObject = ["serverCFI" : serverCFI]
                
                if let body = item["body"] as? [String:AnyObject],
                  let device = body["http://librarysimplified.org/terms/device"] as? String,
                  let time = body["http://librarysimplified.org/terms/time"] as? String
                {
                  responseObject["device"] = device
                  responseObject["time"] = time
                }
                
                Log.info(#file, "\(responseObject["serverCFI"])")
                completionHandler(responseObject)
                return
              }
            }
          } else {
            completionHandler(nil)
            return
          }
          
        }
      }
      dataTask.resume()
    }
    else
    {
      completionHandler(nil)
      return
    }
  }
  
  class var headers: [String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
    
    print("\nNYPLAnnotations::headers: authenticationString: \(authenticationString)")
    print("\nNYPLAnnotations::headers: authenticationValue: \(authenticationValue)")
    
    return ["Authorization" : "\(authenticationValue)",
            "Content-Type" : "application/json"]
  }
}
