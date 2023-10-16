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
    var player = SKSpriteNode(imageNamed: "ship-still")
    var isPlayerAlive = false
    var isRotatingLeft = false
    var isRotatingRight = false
    var isThrustOn = false
    var isHyperSpacingOn = false
    
    // Control Properties
    private var rotation: CGFloat = 0 {
        didSet {
            player.zRotation = deg2rad(degrees: rotation)
        }
    }
    let rotaionFactor: CGFloat = 4 // larger number will cause faster rotation
    var xVector: CGFloat = 0
    var yVector: CGFloat = 0
    var rotationVector: CGVector = .zero
    let thrustFactor: CGFloat = 1.0 // larger number will cause faster thrust - 10 is super fast, 0.1 is super slow
    let thrustSound = SKAction.repeatForever(SKAction.playSoundFileNamed("thrust.wav", waitForCompletion: true))
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        setupLabelsAndButtons()
        createPlayer(atX: frame.width/2, atY: frame.height/2)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isRotatingLeft {
            rotation += rotaionFactor
            if rotation == 360 { rotation = 0 }
        } else if isRotatingRight {
            rotation -= rotaionFactor
            if rotation < 0 { rotation = 360 - rotaionFactor }
        }
        
        if isThrustOn {
            xVector = sin(player.zRotation) * -thrustFactor
            yVector = cos(player.zRotation) * thrustFactor
            rotationVector = CGVector(dx: xVector, dy: yVector)
            player.physicsBody?.applyImpulse(rotationVector)
        }
        
        if player.position.y > frame.height { player.position.y = 0 }
        if player.position.y < 0 { player.position.y = frame.height }
        if player.position.x > frame.width { player.position.x = 0 }
        if player.position.x < 0 { player.position.x = frame.width }
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
        case "thrust":
            isThrustOn = true
            player.texture = SKTexture(imageNamed: "ship-moving")
            scene?.run(thrustSound, withKey: "thrustSound")
        case "hyper":
            animateHyperSpace()
        case "fire":
            createPlayerBullet()
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
        case "thrust":
            isThrustOn = false
            player.texture = SKTexture(imageNamed: "ship-still")
            scene?.removeAction(forKey: "thrustSound")
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
    
    func animateHyperSpace() {
        let outAnimation: SKAction = SKAction(named: "outAnimation")!
        let inAnimation: SKAction = SKAction(named: "inAnimation")!
        let randomX = CGFloat.random(in: 100...1948)
        let randomY = CGFloat.random(in: 150...1436)
        let stopShooting = SKAction.run {
            self.isHyperSpacingOn = true
        }
        let startShooting = SKAction.run {
            self.isHyperSpacingOn = false
        }
        let movePlayer = SKAction.move(to: CGPoint(x: randomX, y: randomY), duration: 0)
        let wait = SKAction.wait(forDuration: 0.25)
        let animation = SKAction.sequence([stopShooting, outAnimation, wait, movePlayer, wait, inAnimation, startShooting])
        player.run(animation)
    }
    
    func createPlayerBullet() {
        guard isHyperSpacingOn == false && isPlayerAlive == true else { return }
        
        let bullet = SKShapeNode(ellipseOf: CGSize(width: 3, height: 3))
        let shotSound = SKAction.playSoundFileNamed("fire.wav", waitForCompletion: false)
        let move = SKAction.move(to: findDestination(start: player.position, angle: rotation), duration: 0.5)
        let sequence = SKAction.sequence([shotSound, move, .removeFromParent()])
        
        bullet.position = player.position
        bullet.zPosition = 0
        bullet.fillColor = .white
        bullet.name = "playerBullet"
        addChild(bullet)
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.isDynamic = true
        bullet.run(sequence)
    }
}
