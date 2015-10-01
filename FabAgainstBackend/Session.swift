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
    
    // Maybe move this...
    var q13Range = [0, ]
    var cardsQuestion13: [[String: AnyObject]] = []
    var cardsAnswer13: [[String: AnyObject]] = []
    var cardsQuestion21: [[String: AnyObject]] = []
    var cardsAnswer21: [[String: AnyObject]] = []
    
    override func onJoin() {
        // Load cards
        cardsQuestion13 = loadCards("q13")
        cardsAnswer13 = loadCards("a13")
        cardsQuestion21 = loadCards("q21")
        cardsAnswer21 = loadCards("a21")
        
        register("pd.demo.cardsagainst/play", getRoom)
    }
    
    func getRoom(player: String) -> AnyObject {
        // Assign the player to a room. Returns cards for the player
        let emptyRooms = rooms.filter { $0.players.count <= ROOM_CAP }
        var room: Room
        
        if emptyRooms.count == 0 {
            room = Room(session: self, questions: cardsQuestion13, answers: cardsAnswer13)
            rooms.append(room)
        } else {
            room = emptyRooms[Int(arc4random_uniform(UInt32(emptyRooms.count)))]
        }
        
        return room.addPlayer(player)
    }
}

func loadCards(name: String) -> [[String: AnyObject]] {
    let jsonPath = NSBundle.mainBundle().pathForResource(name, ofType: "json")
    //let jsonPath = NSBundle.mainBundle().URLForResource(name, withExtension: "json")
    //let man = NSFileManager.defaultManager().currentDirectoryPath
    //print(man)
    
    print(jsonPath)
    let x = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: jsonPath!)!, options: NSJSONReadingOptions.AllowFragments)
    
//    return [[:]]
    
    return x as! [[String: AnyObject]]
}