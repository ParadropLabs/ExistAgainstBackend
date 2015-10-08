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
let EMPTY_TIME = 1.0

// a silly little hack until I get the prefixes in place
let ID = "pd.demo.cardsagainst"


class Room: NSObject {
    var name = ID + "/room" + randomStringWithLength(6)
    var deck: Deck
    var state: State = .Empty
    
    var demoPlayer: Player?
    var players: [Player] = []
    var chooser: Player?
    var session: Session
    
    var timer: NSTimer?
    var question: Card?
    
    
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
        
        
        // If there are not enough players to begin play, inject a demo player
        // DEFER
        defer {
//            if players.count == 1 {
//                let ret = addPlayer("pd.demo.cardsagainst.demo")
//                startPicking()
//            }
            
            // Wait a second to start picking
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

    }
    
    func playerLeft(domain: String) {
        print("Player left: " + domain)
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
        print("STATE: Picking")
        state = .Picking
        
        // TODO: clean up demo players sticking around that we no longer need
        
        // TODO: the chooser from the last round should not get a card (no burn)
        for player in players  {
            player.pick = -1
            session.call(player.domain + "/draw", deck.drawCards(deck.answers, number: 1)[0].json(), handler:nil)
        }
        
        question = deck.drawCards(deck.questions, number: 1)[0]
        
        chooser = players[Int(arc4random_uniform(UInt32(players.count)))]
        session.publish(name + "/round/picking", chooser!.domain, question!)
        startTimer(PICK_TIME, selector: "startChoosing")
    }
    
    func pick(domain: String, card: Int) {
        print("Player \(domain) picked \(card)")
        
        // Ensure state, throw exception
        if state != .Picking {
            print("ERROR: pick called in state \(state)")
            return
        }
        
        // get the player
        let player = getPlayer(players, domain: String(domain))
        
        if player.pick != -1 {
            print("Player has already picked a card.")
            return
        }
        
        player.pick = Int(card)
        
        // TODO: ensure the player reported a legitmate pick-- remove the pick from the player's cards
        // and check the card exists in the first place
        
        session.publish(name + "/play/picked", player.domain)
        
        // Check and see if all players have picked cards. If they have, end the round early.
        let notPicked = players.filter { $0.pick == -1 && $0.domain != chooser!.domain}
        if notPicked.count == 0 {
            print("All players picked. Ending timer early. ")
            startTimer(0.1, selector: "startChoosing")
        }
    }
    
    
    // MARK: Choosing
    func startChoosing() {
        print("STATE: choosing")
        
        // Autoassign picks for the user if they had not yet submitted
        // TODO: inform them off the autopick
        //for p in players {
        //    if p.pick == -1 {
        //        p.pick = randomElement(deck.answers).id
        //    }
        //}
        
        // publish the picks-- with mantle changes this should turn into direct object transference
        
        // get the cards from the ids of the picks
        var ret : [AnyObject] = []
        for p in players {
            let cards = deck.answers.filter {$0.id == p.pick }
            
            if cards.count == 1 {
                ret.append(cards[0].json())
            }
        }
        
        session.publish(name + "/round/choosing", ret)
        
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
            session.publish(name + "/round/scoring", p.domain)
        } else {
            print("No players picked cards! No winers found. ")
            session.publish(name + "/round/scoring", "")
        }
        
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
}


