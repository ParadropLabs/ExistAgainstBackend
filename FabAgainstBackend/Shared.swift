//
//  Shared.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 10/1/15.
//  Copyright © 2015 paradrop. All rights reserved.

// This code is shared across the app and the container.

import Foundation

// Representation of a player in the game
class Player: Equatable {
    var domain: String
    var score = 0
    var pick: Int
    
    init(domain d: String) {
        pick = -1
        domain = d
    }
    
    init(json: [String: AnyObject]) {
        domain = json["domain"] as! String
        score = json["score"] as! Int
        pick = json["pick"] as! Int
    }
    
    func toJson() -> [String: AnyObject] {
        return [
            "domain": domain,
            "score": score,
            "pick": pick
        ]
    }
}

class Card: Equatable {
    var id: Int
    var text: String
    
    init(json: [String: AnyObject]) {
        id = json["id"] as! Int
        text = json["text"] as! String
    }
    
    func json() -> [String: AnyObject] {
        return [
            "id": id,
            "text": text
        ]
    }
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
        //Takes the paths of the JSON source files, creates cards
        questions = loadCards(questionPath).map { Card(json: $0) }
        answers = loadCards(answerPath).map { Card(json: $0) }
    }
    
    func loadCards(name: String) -> [[String: AnyObject]] {
        let jsonPath = NSBundle.mainBundle().pathForResource(name, ofType: "json")
        let x = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: jsonPath!)!, options: NSJSONReadingOptions.AllowFragments)
        return x as! [[String: AnyObject]]
    }
    
    func drawCards(cards: [Card], number: Int) -> [Card] {
        // draws a number of cards for the player. Tracks duplicates (?)
        var ret: [Card] = []
        
        for _ in 0...number {
            ret.append(randomElement(cards))
        }
        
        return ret
    }
}

func getPlayer(players: [Player], domain: String) -> Player {
    return players.filter({$0.domain == domain})[0]
}

enum State {
    case Empty, Picking, Choosing, Scoring
    
    init?(_ raw: String) {
        switch raw {
        case "Empty": self = .Empty;
        case "Picking": self = .Picking;
        case "Choosing": self = .Choosing;
        case "Scoring": self = .Scoring;
        default: return  nil
        }
    }
    
    var description : String {
        switch self {
            case .Empty: return "Empty";
            case .Picking: return "Picking";
            case .Choosing: return "Choosing";
            case .Scoring: return "Scoring";
        }
    }
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

func randomElement<T>(arr: [T]) -> T {
    // returns a random element from an array
    return arr[Int(arc4random_uniform(UInt32(arr.count)))]
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

