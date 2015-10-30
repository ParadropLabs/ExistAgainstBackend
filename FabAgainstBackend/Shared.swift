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


class Deck {
    var questions: [Card] = []
    var answers: [Card] = []
    
    init(questionPath: String, answerPath: String) {
        let load = { (name: String) -> [Card] in
            let jsonPath = NSBundle.mainBundle().pathForResource(name, ofType: "json")
            let x = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: jsonPath!)!, options: NSJSONReadingOptions.AllowFragments) as! [[String: AnyObject]]
            return x.map({ (json: [String: AnyObject]) -> Card in
                let card = Card()
                card.id = json["id"] as! Int
                card.text = json["text"] as! String
                return card
            })
        }
        
        questions = load(questionPath)
        answers = load(answerPath)
    }
    
    func drawCards(var cards: [Card], number: Int, remove: Bool = true) -> [Card] {
        var ret: [Card] = []
        
        for _ in 0...number {
            ret.append(randomElement(&cards, remove: remove))
        }
        
        return ret
    }
    
    func reshuffleCards(inout target: [Card], cards: [Card]) {
        // "Realease" the cards formerly in play by shuffling them back into the deck 
        target.appendContentsOf(cards)
    }
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

