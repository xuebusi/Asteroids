//
//  GameScene.swift
//  Asteroids
//
//  Created by The Architect.
//  ©The Architect Labs - 2023
//  Website:  https://thearchitectlabs.github.io
//  YouTube:  https://www.youtube.com/@thearchitectlabs
//

import SpriteKit

class GameScene: SKScene {
    // MARK: - PROPERTIES
    private var left: SKSpriteNode?
    private var right: SKSpriteNode?
    private var hyper: SKSpriteNode?
    private var thrust: SKSpriteNode?
    private var fire: SKSpriteNode?
    
    // Player Properties
    private var player = SKSpriteNode(imageNamed: "ship-still")
    private var isPlayerAlive = false
    private var isRotatingLeft = false
    private var isRotatingRight = false
    
    // Control Properties
    private var rotation: CGFloat = 0 {
        didSet {
            player.zRotation = deg2rad(degrees: rotation)
        }
    }
    let rotaionFector: CGFloat = 4 // larger number will cause faster rotation
    var xVector: CGFloat = 0
    var yVector: CGFloat = 0
    var rotationVector: CGFloat = .zero
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        setupLabelsAndButtons()
        createPlayer(atX: frame.width/2, atY: frame.height/2)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isRotatingLeft {
            rotation += rotaionFector
            if rotation == 360 { rotation = 0 }
        } else if isRotatingRight {
            rotation -= rotaionFector
            if rotation < 0 { rotation = 360 - rotaionFector }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else { return }
        
        switch tapped.name {
        case "left":
            isRotatingLeft = true
            isRotatingRight = false
        case "right":
            isRotatingLeft = false
            isRotatingRight = true
        default:
            return
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else { return }
        
        switch tapped.name {
        case "left":
            isRotatingLeft = false
            isRotatingRight = false
        case "right":
            isRotatingLeft = false
            isRotatingRight = false
        default:
            return
        }
    }
    
    // MARK: - NODE METHODS
    private func setupLabelsAndButtons() {
        left = childNode(withName: "left") as? SKSpriteNode
        right = childNode(withName: "right") as? SKSpriteNode
        hyper = childNode(withName: "hyper") as? SKSpriteNode
        thrust = childNode(withName: "thrust") as? SKSpriteNode
        fire = childNode(withName: "fire") as? SKSpriteNode
    }
    
    func createPlayer(atX: Double, atY: Double) {
        guard childNode(withName: "player") == nil else { return }
        player.position = CGPoint(x: atX, y: atY)
        player.zPosition = 0
        player.size = CGSize(width: 120, height: 120)
        player.name = "player"
        player.texture = SKTexture(imageNamed: "ship-still")
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: player.texture ?? SKTexture(imageNamed: "ship-still"), size: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.isDynamic = true
        player.physicsBody?.mass = 0.2
        player.physicsBody?.allowsRotation = false
        
        isPlayerAlive = true
    }
}
