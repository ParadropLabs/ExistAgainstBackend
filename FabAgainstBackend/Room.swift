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

let PICK_TIME = 15.0
let CHOOSE_TIME = 8.0
let SCORE_TIME = 3.0
let EMPTY_TIME = 1.0
let MIN_PLAYERS = 4

// a silly little hack until I get the prefixes in place
let ID = "pd.demo.cardsagainst"


class Room: NSObject {
    var session: Session
    var name = ID + "/room" + randomStringWithLength(6)
    
    var state: State = .Empty
    var deck: Deck
    var players: [Player] = []
    
    var timer: NSTimer?
    
    
    init(session s: Session, deck d: Deck) {
        session = s
        deck = d
        
        super.init()
        
        session.register(name + "/leave", playerLeft)
        session.register(name + "/play/pick", pick)
        session.subscribe(name + "/play/choose", choose)
    }
    
    
    // MARK: Player Changes
    func addPlayer(domain: String) -> [String: AnyObject] {
        print("Adding Player \(domain)")
        // Called from main session when player assigned to the room
        // Returns the information the player needs to get up to date
        
        // TODO: Assumes no duplicates, obviously
        let player = Player()
        player.domain = domain
        
        players.append(player)
        session.publish(name + "/joined", domain)
        
        // Check and see if we need to add players to the room
        checkDemo()
        
        // Begin the round after we handshake with the player
        defer {
            if players.count > 1 {
                startTimer(EMPTY_TIME, selector: "startPicking")
            } else {
                print("Not enough players to start play. Waiting")
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

    func checkDemo() {
        // if there are not enough players to play, add demo players until there are at least MIN_PLAYERS in the room
        while players.count < MIN_PLAYERS {
            let demo = Player()
            demo.demo = true
            demo.domain = "Bot--" + randomStringWithLength(3)
            demo.hand = deck.drawCards(deck.answers, number: HAND_SIZE)
            players.append(demo)
            session.publish(name + "/joined", demo.domain)
        }
        
        // TODO: If there are more than enough players to play, remove extra demo players
        // Be careful: can't do this in the middle of a round
    }
    
    func playerLeft(player: Player) {
        print("Player left: " + player.domain)

        session.publish(name + "/left", player)
        
        // if there are not enough players remaining add a demo 
        // Can we do this here? Arbitrarily?
        checkDemo()
        
        // TODO: What if the chooser leaves? Replace with a demo user?
        // TODO: if there are only demo players left in the room, close the room
    }
    
    
    // MARK: Picking
    func startPicking() {
        print("STATE: Picking")
        state = .Picking
        
        // TODO: the chooser from the last round should not get a card (no burn)
        _ = players.map { $0.pick = nil }
        
        let question = deck.drawCards(deck.questions, number: 1)[0]
        
        let chooser = setNextChooser()
        session.publish(name + "/round/picking", chooser, question, PICK_TIME)
        startTimer(PICK_TIME, selector: "startChoosing")
    }
    
    func pick(player: Player, card: Card) {
        print("Player \(player) picked \(card)")
        
        // Ensure state, throw exception
        if state != .Picking {
            print("ERROR: pick called in state \(state)")
            return
        }
        
        if player.pick != nil {
            print("Player has already picked a card.")
            return
        }
        
        if !player.hand.contains(card) {
            print("Player picked a card they dont have!")
            return
        }
        
        player.pick = card
        player.hand.removeObject(card)
        
        session.publish(name + "/play/picked", player)
        
        // Check and see if all players have picked cards. If they have, end the round early.
        let notPicked = players.filter { $0.pick == nil && $0.domain != getChooser()!.domain}
        
        if notPicked.count == 0 {
            print("All players picked. Ending timer early. ")
            startTimer(0.1, selector: "startChoosing")
        }
    }
    
    
    // MARK: Choosing
    func startChoosing() {
        print("STATE: choosing")
        
        // Autoassign picks for the user if they habd not yet submitted
        // TODO: inform them off the autopick
        // for p in players {
        //    if p.pick == -1 {
        //        p.pick = randomElement(deck.answers).id
        //    }
        //}
        
        // publish the picks-- with mantle changes this should turn into direct object transference
        
        // get the cards from the ids of the picks
        var cards = players.map { $0.pick }
        cards = cards.filter { $0 != nil }
        var ret : [AnyObject] = []
        for p in players {
            let cards = deck.answers.filter {$0.id == p.pick }
            
            if cards.count == 1 {
                ret.append(cards[0].json())
            }
        }
        
        session.publish(name + "/round/choosing", ret, CHOOSE_TIME)
        
        state = .Choosing
        startTimer(CHOOSE_TIME, selector: "startScoring:")
    }
    
    func choose(card: Int) {
        // find the person who played this card
        let picks = players.filter { $0.pick == Int(card) }
        
        if picks.count == 0 {
            print("No one played the choosen card \(card)")
            // TODO: Choose on at random? This is malicious activity or a serious bug
        } else if picks.count != 1 {
            print("More than one winning pick selected!")
        }
        
        let domain = picks[0].domain
        print("Winner choosen: " + domain)
        
        startTimer(0.0, selector: "startScoring:", info: domain)
    }
    
    
    //MARK: Scoring
    func startScoring(timer: NSTimer) {
        print("STATE: scoring")
        state = .Scoring
        
        // if nil, no player was choosen. Autochoose one.
        var player: Player?
        if let info = timer.userInfo {
            let domain = info as! String
            let filters = players.filter { $0.domain == domain }
            
            // Make sure we weren't lied to
            if filters.count != 1 {
                print("ERR: submission \(domain) not found in players!")
            } else {
                player = filters[0]
            }
            
        } else {
            var submitted = players.filter { $0.pick != -1 }
            
            if submitted.count != 0 {
                print("No player choosen. Selecting one at random from those that submitted")
                player = randomElement(&submitted)
            }
        }
        
        // We have a winner or not. Publish.
        if let p = player {
            p.score += 1
            session.publish(name + "/round/scoring", p.domain, SCORE_TIME)
        } else {
            print("No players picked cards! No winers found. ")
            session.publish(name + "/round/scoring", "", SCORE_TIME)
        }

        // draw cards for all players
        players.map { session.call($0.domain + "/draw", deck.drawCards(deck.answers, number: 1)[0].json(), handler:nil) }
        
        startTimer(SCORE_TIME, selector: "startPicking")
    }
    
    
    //MARK: Utils
    func startTimer(time: NSTimeInterval, selector: String, info: AnyObject? = nil) {
        // Run the timer for the given target with the given parameters. 
        // Cancels the existing timer if called while one is active
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        
        print("Starting timer for \(time) on \(selector)")
        timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: Selector(selector), userInfo: info, repeats: false)
    }
    
    func cancelTimer() {
        if let t = timer {
            t.invalidate()
            timer = nil
        }
    }
    
    func setNextChooser() -> Player {
        let f = players.filter { $0.chooser == true }
        let player = f.count == 0 ? players[0] : players[players.indexOf(f[0])! + 1 % (players.count - 1)]
        player.chooser = true
        return player
    }
    
    func getChooser() -> Player? {
        let f = players.filter { $0.chooser == true }
        if f.count != 1 {
            print("No chooser found!")
            return nil
        }
        
        return f[0]
    }
}


