//
//  Shared.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 10/1/15.
//  Copyright © 2015 paradrop. All rights reserved.

// This code is shared across the app and the container.

import Foundation
import Riffle

class Player: RiffleModel {
    var id = -1
    
    var domain = ""
    var score = 0
    
    var chooser = false
    var hand: [Card] = []
    var pick: Card?
    
    override static func JSONKeyPathsByPropertyKey() -> [NSObject : AnyObject]!  {
        // By default, do not pass along nested model objects
        
        var keys = super.JSONKeyPathsByPropertyKey()
        keys["hand"] = NSNull()
        keys["pick"] = NSNull()
        return keys
    }
}

class Card: RiffleModel {
    var id = -1
    var text = ""
}

func ==(lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}

func ==(lhs: Player, rhs: Player) -> Bool {
    return lhs.domain == rhs.domain
}

func getPlayer(players: [Player], domain: String) -> Player {
    return players.filter({$0.domain == domain})[0]
}

// Utility function to generate random strings
func randomStringWithLength (len : Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for (var i=0; i < len; i++){
        let rand = arc4random_uniform(UInt32(letters.length))
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return String(randomString)
}

func randomElement<T>(inout arr: [T], remove: Bool = false) -> T {
    let i = Int(arc4random_uniform(UInt32(arr.count)))
    let o = arr[i]
    
    if remove {
        arr.removeAtIndex(i)
    }
    
    return o
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

