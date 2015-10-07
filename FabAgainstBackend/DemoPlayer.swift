//
//  File.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 10/2/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

// A dummy player that demonstrates simple usage when a room is empty
import Foundation

class Dummy: Player {
    var cards: [Card] = []
    
    func randomPick() -> Card {
        let card = randomElement(&cards)
        cards.removeObject(card)
        return card
    }
}