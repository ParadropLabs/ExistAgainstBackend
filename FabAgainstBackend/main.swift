//
//  main.swift
//  FabAgainstBackend
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

import Foundation
import Riffle

setFabric("ws://ubuntu@ec2-52-26-83-61.us-west-2.compute.amazonaws.com:8000/ws")
Session(domain: "pd.demo.cardsagainst").connect()
NSRunLoop.currentRunLoop().run()

