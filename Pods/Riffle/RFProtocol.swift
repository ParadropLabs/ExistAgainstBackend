//
//  RiffleCore.swift
//  Pods
//
//  Created by Mickey Barboi on 10/2/15.
//
//

// Starting off as a light wrapper for wamp, but moving up quickly.

import Foundation

class RFProtocol: MDWamp {
    override func connect() {
        self.transport.open()
    }
}