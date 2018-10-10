//
//  NYPLHoldsScheduler.swift
//  SimplyE
//
//  Created by Vui Nguyen on 10/2/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLHoldsScheduler {

  var myBooks: [NYPLBook] = []
  var reservedBooks: [NYPLBook] = []
  var catalogBooks: [NYPLBook] = []
  var catalogBooksWithHolds: [NYPLBook] = []

  init() {
    print("initialize NYPLHoldsScheduler")
    getMyBooks()
    getReservedBooks()
  }
  deinit {
    print("deinitialize NYPLHoldsScheduler")
  }

  // book in the My Books tab
  func getMyBooks() {
    if let booksInMyTab = NYPLBookRegistry.shared()?.myBooks as? [NYPLBook] {
      myBooks = booksInMyTab
      print(myBooks)
    } else {
      print("getMyBooks: these are NOT NYPLBooks")
    }
  }

  // check on the states of the Reservations tab: are they "on hold" or
  // ready for checkout?
  // For those "on hold" can we get the hold times?
  // at some point, call sync and check again (may not be necessary if
  // HoldsViewController is already listening for changes via NotificationCenter)
  // can call sync manually by getting the spinning thing to work

  // books in the Reservations tab, or on hold
  func getReservedBooks() {
    if let booksInMyReservationsTab = NYPLBookRegistry.shared()?.heldBooks as? [NYPLBook] {
      reservedBooks = booksInMyReservationsTab
      print(reservedBooks)
    } else {
      print("getReservedBooks: these are NOT NYPLBooks!")
    }
  }

  // this is NOT going to work!
  func getCatalogBooksWithHolds() {
    if let booksInCatalogTab = NYPLBookRegistry.shared()?.allBooks as? [NYPLBook] {
      catalogBooks = booksInCatalogTab
      print("Number of books in catalog are: \(catalogBooks.count)")

      // change this so that it's the count or less
      for index in 0..<catalogBooks.count {
        print("Availability of book \(String(describing: catalogBooks[index].title)): \(catalogBooks[index].acquisitions[0].availability)")
      }
    } else {
      print("getCatalogBooksWithHoldTimes: these are NOT NYPLBooks!")
    }
  }
}
