//
//  Room.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

// A collection of players in one place.

import Foundation


class Room {
    var name: String
    var closing: (Room) -> ()
    
    init(name: String, onClose: (Room) -> ()) {
        name = name
        closing = onClose
    }
}


// MARK: Player
class Player {
    var id: String
    var score: Int
}