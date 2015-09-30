//
//  Room.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

/*
    A room is a  game between a limited set of players. Creates a random string
    which it appends to /room for its endpoints.

    Gameplay proceeds in rounds which consist of phases.

    Publishes on:
    /room/round/picking
    /room/round/choosing
    /room/round/scoring
    /room/round/cancel
    /room/round/tick

    /room/joined
    /room/left
    /room/closed

    /room/play/picked

    Registers:
    /room/current
    /room/play/pick

*/

import Foundation

enum State {
    case Empty, Picking, Choosing, Scoring
}


class Room {
    var name = randomStringWithLength(6)
    var players: [Player] = []
    var chooser: Player?
    var session: Session
    var state: State = .Empty
    var timer: AnyObject?
    
    var questions: [[String: AnyObject]]
    var answers: [[String: AnyObject]]
    
    
    init(session s: Session, questions q: [[String: AnyObject]], answers a: [[String: AnyObject]]) {
        session = s
        questions = q
        answers = a
        
        //subscribe playerLeft
    }
    
    
    // MARK: Player Changes
    func addPlayer(id: String) -> [Int] {
        // Called from main session when players arrive
        // return room information to the player
        // return cards to the player
        
        // Assumes no duplicates, obviously
        players.append(Player(pdid: id))
        
        //publish join
        
        // Check if we have enough people to start playing
        if players.count > 1 {
            startPicking()
        }
        
        // draw cards for the player
        var hand: [Int] = []
        for _ in 0...HAND_SIZE {
            hand.append(randomElement(answers)["id"] as! Int)
        }
        
        return hand
    }
    
    func playerLeft(id: String) {
        // get player that left
        // If chooser, cancel and reassign
        // Publish leave
        
        // Make sure we have enough players to play
        if players.count < 2 {
            //stop timer
            //publish cancel
        }
    }
    
    
    // MARK: Picking
    func startPicking() {
        state = .Picking
        
        // reset picked state
        _ = players.map { $0.pick = nil }
        
        // draw cards for players
        
        // choose next player in round robin
        // chooser = chooser == nil ? players[0] : players[players.indexOf(chooser!) + 1 % players.count()]
        
        // session.publish("/room/round/", newChooser)
        // Start timer
    }
    
    func pick(id: String, card: Int) {
        // Ensure state, throw exception
        
        // get the player
        let player = getPlayer(id)
        
        if player.pick != nil {
            print("Player has already picked a card.")
            return
        }
        
        player.pick = card
        
        //remove card from player
        
        // publish picked
    }
    
    // MARK: Choosing
    func startChoosing() {
        state = .Choosing
        
        // publish picks
        // start timer
    }
    
    func chose(id: String) {
        // stop timer
        startScoring(getPlayer(id))
    }
    
    
    //MARK: Scoring
    func startScoring(player: Player?) {
        state = .Scoring
        
        if let p = player {
            p.score += 1
        }
        
        // if called with nil, no one chose. Else publish the winner.
        // publish scoring
        
        // start timer
    }
    
    
    // MARK: Utils
    func getPlayer(id: String) -> Player {
        return players.filter({$0.id == id})[0]
    }
    
    func drawCards(number: Int) -> [Int] {
        // draws a number of cards for the player. Tracks duplicates (?)
        var ret: [Int] = []
        
        let TEMPCARDS = [1, 2, 3]
        
        for _ in 0...number {
            ret.append(randomElement(TEMPCARDS))
        }
        
        return ret
    }
}


class Player {
    var id: String
    var score = 0
    var pick: Int?
    
    init(pdid: String) {
        id = pdid
    }
}


// Utility function to generate random strings
func randomStringWithLength (len : Int) -> NSString {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for (var i=0; i < len; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString
}

func randomElement<T>(arr: [T]) -> T {
    // returns a random element from an array
    return arr[Int(arc4random_uniform(UInt32(arr.count)))]
}
