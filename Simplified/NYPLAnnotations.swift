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
    
  class func postBookmark(_ book:NYPLBook, cfi:NSString, completionHandler: @escaping () -> Void)
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
    
        postJSONRequest(book, url, parameters, NYPLAnnotations.headers, completionHandler)
      } else {
         Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
    
  class func deleteBookmark(annotationId:NSString, completionHandler: @escaping () -> Void)
  {
        // For this, all we need are URL and the headers
        // in fact, the annotation ID is exactly the same as the URL that we need
    
    let url: URL = URL(string: annotationId as String)!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    
    if let headers = NYPLAnnotations.headers as [String:String]? {
        for (headerKey, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerKey)
        }
    }
    
    // for now, run the completionHandler only when one exists
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if let response = response as? HTTPURLResponse {
            print("NYPLAnnotations::deleteBookmark, response.statusCode is \(response.statusCode)")
            
            if response.statusCode == 200 {
                // run completion handler if one  exists
                completionHandler()
            }
        } else {
            guard let error = error as? NSError else { return }
            
            Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
        }
    }
    task.resume()
  }
    
  class func syncAllBookmarks(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [[String:String]]?) -> ())
  {
    print("NYPLAnnotations::syncAllBookmarks called");
    syncLastBookmarks(book, completionHandler: completionHandler)
  }
    
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ())
  {
    syncLastRead(book, completionHandler: completionHandler)
  }
  
    // this one is different from the other postJSONRequest in that it has a completionHandler
    private class func postJSONRequest(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any], _ headers: [String:String]?,
                                       _ completionHandler: @escaping () -> Void)
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
                    completionHandler()
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
      print("NYPLAnnotations::syncLastRead, book.annotationsURL is: \(book.annotationsURL)")
        
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
          
          print("NYPLAnnotations::syncLastRead, response is: \(response)")
          print("NYPLAnnotations::syncLastRead, data is \(data)")
            
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
            
            print("NYPLAnnotations::syncLastRead, total is: \(total)")
            for item in items
            {
              
              guard let target = item["target"] as? [String:AnyObject], let source = target["source"] as? String else {
                completionHandler(nil)
                return
              }
              
              print("NYPLAnnotations::syncLastRead, book.identifier is: \(book.identifier)")
                
              if source == book.identifier
              {
                
                guard let selector = target["selector"] as? [String:AnyObject], let serverCFI = selector["value"] as? String else {
                  completionHandler(nil)
                  return
                }
                
                print("NYPLAnnotations::syncLastRead, serverCFI is: \(serverCFI)")
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
 
              } // this ends source == book.identifier
            }   // this ends for item in items
            
          }
          else {
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
  

    private class func syncLastBookmarks(_ book:NYPLBook, completionHandler: @escaping (_ responseObjectArray: [[String:String]]?) -> ()) {
        
        if (NYPLAccount.shared().hasBarcodeAndPIN() && book.annotationsURL != nil)
        {
            print("NYPLAnnotations::syncLastBookmarks, book.annotationsURL is: \(book.annotationsURL)")
            
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
                    
                    //print("NYPLAnnotations::syncLastBookmarks, response is: \(response)")
                    //print("NYPLAnnotations::syncLastBookmarks, data is \(data)")
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any] else {
                        Log.error(#file, "JSON could not be created from data.")
                        completionHandler(nil)
                        return
                    }
                    
                    guard let first = json["first"] as? [String:AnyObject], let items = first["items"] as? [AnyObject] else {
                        completionHandler(nil)
                        return
                    }
                    
                    
                    guard let total:Int = json["total"] as? Int else {
                        completionHandler(nil)
                        return
                    }
                    
                    var responseObjectArray = [[String:String]]()
                    if total > 0
                    {
                        // let's grab the device, time, and CFI; and annotation id
                        for item in items
                        {
                            var responseObject = [String:String]()
                            
                            
                            guard let motivation = item["motivation"] as? String else {
                                    completionHandler(nil)
                                    return
                            }
  
                            print("NYPLAnnotations::syncLastBookmarks, motivation is: \(motivation)")
                            if (motivation.lowercased().contains("bookmarking"))
                            {
                                responseObject["motivation"] = motivation
                            }
                            else
                            {
                                continue;
                            }
                            
                            guard let id = item["id"] as? String else {
                                completionHandler(nil)
                                return
                            }
                            responseObject["id"] = id
                            
                            guard let target = item["target"] as? [String:AnyObject],
                                let selector = target["selector"] as? [String:AnyObject],
                                let serverCFI = selector["value"] as? String else {
                                    completionHandler(nil)
                                    return
                            }
                            responseObject["serverCFI"] = serverCFI
                            
                            print("NYPLAnnotations::syncLastBookmarks, serverCFI is: \(serverCFI)")
                            
                            
                            if let body = item["body"] as? [String:AnyObject],
                                let device = body["http://librarysimplified.org/terms/device"] as? String,
                                let time = body["http://librarysimplified.org/terms/time"] as? String
                            {
                                responseObject["device"] = device
                                responseObject["time"] = time
                            }
                            
                            responseObjectArray.append(responseObject)
                        }   // end for item in items
                        
                        print("NYPLAnnotations::syncLastBookmarks, total bookmarks are: \(responseObjectArray.count)")
                        Log.info(#file, "\(responseObjectArray)")
                        completionHandler(responseObjectArray)
                        return
                    }   // end if total > 0
                    else {
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
