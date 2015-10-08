//
//  Session.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

import Foundation
import Riffle

let ROOM_CAP = 6
let HAND_SIZE = 6

class Session: RiffleSession {
    var rooms: [Room] = []
    
    var pg13 = Deck(questionPath: "q13", answerPath: "a13")
    var pg21 = Deck(questionPath: "q21", answerPath: "a21")
    
    override func onJoin() {
        register("pd.demo.cardsagainst/play", getRoom)
    }
    
    func getRoom(player: NSString) -> AnyObject {
        // Assign the player to a room. Returns cards for the player
        
        let emptyRooms = rooms.filter { $0.players.count <= ROOM_CAP }
        var room: Room
        
        if emptyRooms.count == 0 {
            room = Room(session: self, deck: pg13)
            rooms.append(room)
        } else {
            room = emptyRooms[Int(arc4random_uniform(UInt32(emptyRooms.count)))]
        }
        
        // very strange exec_bad_access if you just return the element right away. 
        // Started when I converted the roomclass to an NSObject subclass. No idea....
        let x = room.addPlayer(player as String)
        return x
    }
}