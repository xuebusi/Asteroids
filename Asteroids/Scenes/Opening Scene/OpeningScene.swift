//
//  OpeningScene.swift
//  Asteroids
//
//  Created by The Architect.
//  ©The Architect Labs - 2023
//  Website:  https://thearchitectlabs.github.io
//  YouTube:  https://www.youtube.com/@thearchitectlabs
//

import SpriteKit

class OpeningScene: SKScene {
    // MARK: - PROPERTIES
    private var background: SKSpriteNode?
    private var lblHiScore: SKLabelNode?
    private var lblStart: SKLabelNode?
    private var lblReset: SKLabelNode?
    
    var hiScore: Int = 0 {
        didSet {
            lblHiScore?.text = String(format: "%05d", hiScore)
        }
    }
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        setupLabels()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else { return }
        
        if tapped.name == "lblStart" {
            if let nextScene = SKScene(fileNamed: "GameScene") {
                nextScene.scaleMode = self.scaleMode
                let transition = SKTransition.reveal(with: .left, duration: 1)
                
                // Set the Game Defaults
                UserDefaults.standard.set(0, forKey: userdefaults.score)
                UserDefaults.standard.set(1, forKey: userdefaults.level)
                UserDefaults.standard.set(3, forKey: userdefaults.lives)
                
                // Present the scene
                view?.presentScene(nextScene, transition: transition)
            }
        } else if tapped.name == "lblReset" {
            hiScore = 0
            UserDefaults.standard.set(0, forKey: userdefaults.hiscore)
        } else {
            animateStartLabel()
        }
    }
    
    // MARK: - NODE METHODS
    func setupLabels() {
        background = self.childNode(withName: "background") as? SKSpriteNode
        lblHiScore = self.childNode(withName: "lblHiScore") as? SKLabelNode
        lblStart = self.childNode(withName: "lblStart") as? SKLabelNode
        lblReset = self.childNode(withName: "lblReset") as? SKLabelNode
        
        lblStart?.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        lblReset?.position = CGPoint(x: frame.width - 300, y: 100)
        
        hiScore = UserDefaults.standard.integer(forKey: "hiscore")
    }
    
    func animateStartLabel() {
        let expand = SKAction.scale(to: 1.5, duration: 0.5)
        let rotate = SKAction.rotate(byAngle: deg2rad(degrees: -360), duration: 0.5)
        let contract = SKAction.scale(to: 1.0, duration: 0.5)
        lblStart?.run(SKAction.sequence([expand, rotate, contract]))
    }
}
