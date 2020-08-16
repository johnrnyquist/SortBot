//
//  GameViewController.swift
//  SortBot
//
//  Created by David Roth on 7/2/16.
//  Copyright © 2016 David Roth. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'QuickConquest.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .fill
                view.presentScene(scene)
            }
            view.ignoresSiblingOrder = true
            
            #if DEBUG
            view.showsFPS = true
            view.showsNodeCount = true
            #endif
        }
    }
}
