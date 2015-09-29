//
//  Session.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

import Foundation
import Riffle


class Session: RiffleSession {
    override func onJoin() {
        register("pd.demo.cardsagainst/getRoom", getRoom)
    }
    
    func getRoom() {
        // Assign the given agent to a room
        print("Called")
    }
}