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

let PICK_TIME = 10.0
let CHOOSE_TIME = 5.0
let SCORE_TIME = 2.0

// a silly little hack until I get the prefixes in place
let ID = "pd.demo.cardsagainst"


class Room {
    var name = ID + "/room" + randomStringWithLength(6)
    var deck: Deck
    var state: State = .Empty
    
    var players: [Player] = []
    var chooser: Player?
    var session: Session
    
    var timer: NSTimer?
    
    
    init(session s: Session, deck d: Deck) {
        session = s
        deck = d
        
        session.register(name + "/leave", playerLeft)
    }
    
    
    // MARK: Player Changes
    func addPlayer(domain: String) -> [String: AnyObject] {
        // Called from main session when player assigned to the room
        // Returns the information the player needs to get up to date
        
        // TODO: Assumes no duplicates, obviously
        players.append(Player(domain: domain))
        session.publish(name + "/joined", domain)
        
        // Check if we have enough people to start playing
        defer {
            if players.count > 1 {
                startPicking()
            }
        }
        
        // Return the player's hand, the current players, and the current state
        return [
            "players": players.map { $0.toJson() },
            "state" : String(state),
            "hand" : deck.drawCards(deck.answers, number: HAND_SIZE).map { $0.json() },
            "room" : name
        ]
    }
    
    func playerLeft(domain: String) {
        // Check who the user is! If the chooser left we have to cancel or replace it with a demo user

        session.publish(name + "/left", domain)
        
        // Make sure we have enough players to play
        if players.count < 2 {
            // This round is over, inform the players
            // TODO
            cancelTimer()
            session.publish(name + "/play/cancel")
        }
    }
    
    
    // MARK: Picking
    func startPicking() {
        state = .Picking
        
        for player in players  {
            player.pick = -1
            session.call(player.domain + "/draw", deck.drawCards(deck.answers, number: 1)[0].json(), handler:nil)
        }
        
        chooser = players[Int(arc4random_uniform(UInt32(players.count)))]
        session.publish(name + "/round/picking", chooser!.domain)
        startTimer(PICK_TIME, selector: "startChoosing")
    }
    
    func pick(domain: String, card: Int) {
        // Ensure state, throw exception
        if state != .Picking {
            print("ERROR: pick called in state \(state)")
            return
        }
        
        // get the player
        let player = getPlayer(players, domain: domain)
        
        if player.pick != -1 {
            print("Player has already picked a card.")
            return
        }
        
        player.pick = card
        
        // TODO: ensure the player reported a legitmate pick-- remove the pick from the player's cards
        
        session.publish(name + "/play/cancel", player.pick)
    }
    
    // MARK: Choosing
    func startChoosing() {
        state = .Choosing
        startTimer(CHOOSE_TIME, selector: "startScoring")
    }
    
    func chose(domain: String) {
        cancelTimer()
        startScoring(getPlayer(players, domain: domain))
    }
    
    
    //MARK: Scoring
    func startScoring(player: Player? = nil) {
        state = .Scoring
        
        if let p = player {
            p.score += 1
        }
        
        // if called with nil, no one chose. Else publish the winner.
        // publish scoring
        let winner = players.filter({ $0.pick != -1 })
        
        if winner.count != 1 {
            print("No winner found, count: \(winner)")
            // TODO: all nil to be passed
            session.publish(name + "/play/picked", "")
        } else {
            session.publish(name + "/play/picked", winner[0].domain)
        }
        
        startTimer(SCORE_TIME, selector: "startPicking")
    }
    
    
    //MARK: Utils
    func startTimer(time: NSTimeInterval, selector: String) {
        timer = NSTimer(timeInterval: time, target: self, selector: Selector(selector), userInfo: nil, repeats: false)
    }
    
    func cancelTimer() {
        if let t = timer {
            t.invalidate()
            timer = nil
        }
    }
}


