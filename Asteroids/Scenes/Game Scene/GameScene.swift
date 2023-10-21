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

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - PROPERTIES
    private var left: SKSpriteNode?
    private var right: SKSpriteNode?
    private var hyper: SKSpriteNode?
    private var thrust: SKSpriteNode?
    private var fire: SKSpriteNode?
    
    private var lblScore: SKLabelNode?
    private var lblHiScore: SKLabelNode?
    private var lblGameOver: SKLabelNode?
    private var lblNextLevel: SKLabelNode?
    private var lblLives: SKLabelNode?
    
    // Game Properties
    var score: Int = 0 {
        didSet {
            lblScore?.text = String(format: "%05d", score)
            if score > hiscore { hiscore = score }
            if score > bonusBase * bonusMultiplier {
                lblScore?.run(SKAction.repeat(SKAction.playSoundFileNamed("extraShip", waitForCompletion: true), count: 6))
                bonusMultiplier += 1
                lives += 1
            }
        }
    }
    var hiscore: Int = 0 {
        didSet {
            lblHiScore?.text = String(format: "%05d", hiscore)
            UserDefaults.standard.set(hiscore, forKey: userdefaults.hiscore)
        }
    }
    var lives: Int = 0 {
        didSet {
            lblLives?.text = lives < 1 ? "000" : String(format: "%03d", lives)
        }
    }
    var level: Int = 1
    let bonusBase: Int = 10000
    var bonusMultiplier: Int = 1
    
    // Player Properties
    var player = SKSpriteNode(imageNamed: "ship-still")
    var isPlayerAlive = false
    var isRotatingLeft = false
    var isRotatingRight = false
    var isThrustOn = false
    var isHyperSpacingOn = false
    
    // Enemy Spaceship Properties
    let enemy = SKSpriteNode(imageNamed: "alien-ship")
    var isEnemyAlive = false
    var isEnemyBig = true
    var enemyTimer: Double = 0
    var timeOfLastShot: CFTimeInterval = 0
    
    // Asteroid Properties
    var maxAsteroid: Int = 0
    var totalAsteroids: Int = 0
    
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
    
    // Background Beat Properties
    var timeOfLastBeat: CFTimeInterval = 0
    var beatOffset: Double = 1
    var totalAsteroidsCreatedThisLevel: Double = 0
    var totalAsteroidsDestoryedThisLevel: Double = 0
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        setupLabelsAndButtons()
        createPlayer(atX: frame.width/2, atY: frame.height/2)
        
        enemyTimer = Double.random(in: 1800...7200) // at 60 FPS, this is equivalent to 30...120 seconds
        maxAsteroid = level > 4 ? 11 : 2 + (level * 2)
        totalAsteroidsCreatedThisLevel = Double(maxAsteroid * 7)
        
        for _ in 1...maxAsteroid {
            let randomX: CGFloat = CGFloat.random(in: 0...2048)
            let randomY: CGFloat = CGFloat.random(in: 0...1636)
            let asteroid: Asteroid = Asteroid(imageNamed: "asteroid1")
            asteroid.createAsteroid(atX: randomX, atY: randomY, withWidth: 240, withHeight: 240, withName: "asteroid-large")
            addChild(asteroid)
            totalAsteroids += 1
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if currentTime - timeOfLastBeat > beatOffset {
            lblNextLevel?.run(SKAction.playSoundFileNamed(beatOffset > 0.5 ? "beat1.wav" : "beat2.wav", waitForCompletion: false), withKey: "backgroundBeat")
            timeOfLastBeat = currentTime
        }
        
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
        
        if isEnemyAlive == false {
            if enemyTimer < 0 {
                createEnemySpaceship()
            } else {
                enemyTimer -= 1
            }
        } else {
            if currentTime - timeOfLastShot > 1.0 {
                self.timeOfLastShot = currentTime
                createEnemyBullet()
            }
        }
        
        if enemy.position.y > frame.height { enemy.position.y = 0 }
        if enemy.position.y < 0 { enemy.position.y = frame.height }
        
        for node in self.children {
            if let anAsteroid: Asteroid = node as? Asteroid {
                anAsteroid.moveAsteroid()
                if anAsteroid.position.y > frame.height { anAsteroid.position.y = 0 }
                if anAsteroid.position.y < 0 { anAsteroid.position.y = frame.height }
                if anAsteroid.position.x > frame.width { anAsteroid.position.x = 0 }
                if anAsteroid.position.x < 0 { anAsteroid.position.x = frame.width }
            }
        }
        
        if totalAsteroids == 0 && isEnemyAlive == false && lblNextLevel?.isHidden == true {
            beatOffset = 1.0
            createNextLevel()
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        guard let firstNode = firstBody.node else { return }
        guard let secondNode = secondBody.node else { return }
        
        if firstNode.name == "asteroid-large" || firstNode.name == "asteroid-medium" || firstNode.name == "asteroid-small" {
            if secondNode.name == "enemy-large" || secondNode.name == "enemy-small" || secondNode.name == "enemyBullet" {
                // Asteroid hit enemy || enemy bullet == No points awarded
                breakAsteroid(node: firstNode, name: firstNode.name!, position: firstNode.position)
                destroyNode(node: secondNode, name: secondNode.name!)
            } else if secondNode.name == "player" || secondNode.name == "playerBullet" {
                // Asteroid hit player || player bullet == Points awarded
                breakAsteroid(node: firstNode, name: firstNode.name!, position: firstNode.position)
                destroyNode(node: secondNode, name: secondNode.name!)
                score += firstNode.name == "asteroid-large" ? 20 : firstNode.name == "asteroid-medium" ? 50 : 100
            }
        } else if firstNode.name == "enemy-large" || firstNode.name == "enemy-small" {
            // Enemy hit player || player bullet == Points awarded
            destroyNode(node: firstNode, name: firstNode.name!)
            destroyNode(node: secondNode, name: secondNode.name!)
            score += firstNode.name == "enemy-large" ? 200 : 1000
        } else {
            // Enemy bullet hit player == No points awarded
            destroyNode(node: firstNode, name: firstNode.name!)
            destroyNode(node: secondNode, name: secondNode.name!)
        }
    }
    
    // MARK: - NODE METHODS
    private func setupLabelsAndButtons() {
        left = childNode(withName: "left") as? SKSpriteNode
        right = childNode(withName: "right") as? SKSpriteNode
        hyper = childNode(withName: "hyper") as? SKSpriteNode
        thrust = childNode(withName: "thrust") as? SKSpriteNode
        fire = childNode(withName: "fire") as? SKSpriteNode
        
        lblScore = self.childNode(withName: "lblScore") as? SKLabelNode
        lblHiScore = self.childNode(withName: "lblHiScore") as? SKLabelNode
        lblGameOver = self.childNode(withName: "lblGameOver") as? SKLabelNode
        lblNextLevel = self.childNode(withName: "lblNextLevel") as? SKLabelNode
        lblLives = self.childNode(withName: "lblLives") as? SKLabelNode
        
        lblGameOver?.isHidden = true
        lblNextLevel?.isHidden = true
        
        score = UserDefaults.standard.integer(forKey: userdefaults.score)
        hiscore = UserDefaults.standard.integer(forKey: userdefaults.hiscore)
        lives = UserDefaults.standard.integer(forKey: userdefaults.lives)
        level = UserDefaults.standard.integer(forKey: userdefaults.level)
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
        
        player.physicsBody?.categoryBitMask = CollisionCategory.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue | CollisionCategory.enemyBullet.rawValue
        player.physicsBody?.contactTestBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue | CollisionCategory.enemyBullet.rawValue
        
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
        
        bullet.physicsBody?.categoryBitMask = CollisionCategory.playerBullet.rawValue
        bullet.physicsBody?.collisionBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue
        bullet.physicsBody?.contactTestBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue
    }
    
    func createEnemySpaceship() {
        guard isEnemyAlive == false else { return }
        isEnemyAlive = true
        let startOnLeft = Bool.random()
        let startY = Double.random(in: 150...1436)
        
        isEnemyBig = score > 40000 ? false : Bool.random()
        
        enemy.position = startOnLeft ? CGPoint(x: -100, y: startY) : CGPoint(x: 2248, y: startY)
        enemy.zPosition = 0
        enemy.size = CGSize(width: isEnemyBig ? 120 : 60, height: isEnemyBig ? 129 : 60)
        enemy.name = isEnemyBig ? "enemy-large" : "enemy-small"
        addChild(enemy)
        
        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.isDynamic = true
        
        enemy.physicsBody?.categoryBitMask = CollisionCategory.enemy.rawValue
        enemy.physicsBody?.collisionBitMask = CollisionCategory.player.rawValue | CollisionCategory.asteroid.rawValue | CollisionCategory.playerBullet.rawValue
        enemy.physicsBody?.contactTestBitMask = CollisionCategory.player.rawValue | CollisionCategory.asteroid.rawValue | CollisionCategory.playerBullet.rawValue
        
        let firstMove = SKAction.move(to: startOnLeft ? CGPoint(x: 716, y: startY + Double.random(in: -500...500)) : CGPoint(x: 1432, y: Double.random(in: -500...500)), duration: 3)
        let secondMove = SKAction.move(to: startOnLeft ? CGPoint(x: 1432, y: startY + Double.random(in: -500...500)) : CGPoint(x: 716, y: Double.random(in: -500...500)), duration: 3)
        let thirdMove = SKAction.move(to: startOnLeft ? CGPoint(x: 2248, y: startY + Double.random(in: -500...500)) : CGPoint(x: -100, y: Double.random(in: -500...500)), duration: 3)
        let remove = SKAction.run {
            self.isEnemyAlive = false
            self.enemyTimer = Double.random(in: 1800...7200)
        }
        let sound = SKAction.repeatForever(SKAction.playSoundFileNamed(isEnemyBig ? "saucerBig.wav" : "saucerSmall.wav", waitForCompletion: true))
        let sequence = SKAction.sequence([firstMove, secondMove, thirdMove, .removeFromParent(), remove])
        let group = SKAction.group([sound, sequence])
        enemy.run(group)
    }
    
    func createEnemyBullet() {
        guard isEnemyAlive else { return }
        
        let enemyBullet = SKShapeNode(ellipseOf: CGSize(width: 3, height: 3))
        enemyBullet.position = enemy.position
        enemyBullet.zPosition = 0
        enemyBullet.name = "enemyBullet"
        enemyBullet.fillColor = .white
        enemyBullet.strokeColor = .white
        addChild(enemyBullet)
        
        enemyBullet.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        enemyBullet.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.isDynamic = true
        
        enemyBullet.physicsBody?.categoryBitMask = CollisionCategory.enemyBullet.rawValue
        enemyBullet.physicsBody?.collisionBitMask = CollisionCategory.player.rawValue | CollisionCategory.asteroid.rawValue
        enemyBullet.physicsBody?.contactTestBitMask = CollisionCategory.player.rawValue | CollisionCategory.asteroid.rawValue
        
        let bulletXOffset: Double = isEnemyBig ? 1000 : 525 - Double(level * 25)
        let bulletYOffset: Double = isEnemyBig ? 400 : 210 - Double(level * 10)
        let targetXLeft = player.position.x - bulletXOffset
        let targetXRight = player.position.x + bulletXOffset
        let targetYBottom = player.position.y - bulletYOffset
        let targetYTop = player.position.y + bulletYOffset
        let randomX = Double.random(in: targetXLeft...targetXRight)
        let randomY = Double.random(in: targetYBottom...targetYTop)
        let move = SKAction.move(to: CGPoint(x: randomX, y: randomY), duration: 0.5)
        let sequence = SKAction.sequence([move, .removeFromParent()])
        enemyBullet.run(sequence)
    }
    
    func breakAsteroid(node: SKNode, name: String, position: CGPoint) {
        let sound = SKAction.playSoundFileNamed(name == "asteroid-large" ? "bangLarge.wav" : name == "asteroid-medium" ? "bangMedium.wav" : "bangSmall.wav", waitForCompletion: false)
        let create = SKAction.run {
            for _ in 0...1 {
                let newAsteroid: Asteroid = Asteroid(imageNamed: "asteroid1")
                newAsteroid.createAsteroid(atX: position.x, atY: position.y, withWidth: name == "asteroid-large" ? 120 : 60, withHeight: name == "asteroid-large" ? 120 : 60, withName: name == "asteroid-large" ? "asteroid-medium" : "asteroid-small")
                self.addChild(newAsteroid)
            }
        }
        let destory = SKAction.run {
            self.destroyNode(node: node, name: name)
        }
        let group = SKAction.group([sound, destory])
        let sequence = SKAction.sequence([group, create])
        
        if name == "asteroid-large" || name == "asteroid-medium" {
            scene?.run(sequence)
            totalAsteroids += 1
        } else {
            scene?.run(group)
            totalAsteroids -= 1
        }
        
        totalAsteroidsDestoryedThisLevel += 1
        beatOffset = 1 - min(totalAsteroidsDestoryedThisLevel / totalAsteroidsCreatedThisLevel, 0.8)
    }
    
    func destroyNode(node: SKNode, name: String) {
        if name == "player" {
            node.physicsBody?.contactTestBitMask = 0
            let explode = SKAction(named: "explode")!
            let sequence = SKAction.sequence([explode, .removeFromParent()])
            node.run(sequence)
            node.name = ""
            isPlayerAlive = false
            
            lives -= 1
            if lives < 0 {
                lblGameOver?.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if let openScene = SKScene(fileNamed: "OpeningScene") {
                        openScene.scaleMode = self.scaleMode
                        let transition = SKTransition.reveal(with: .right, duration: 1)
                        self.view?.presentScene(openScene, transition: transition)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.createPlayer(atX: self.frame.width / 2, atY: self.frame.height / 2)
                }
            }
        } else if name == "enemy-large" || name == "enemy-small" {
            node.removeFromParent()
            node.name = ""
            let sound = SKAction.playSoundFileNamed(name == "enemy-large" ? "bangLarge.wav" : "bangSmall.wav", waitForCompletion: false)
            isEnemyAlive = false
            enemyTimer = Double.random(in: 1800...7200)
            scene?.run(sound)
        } else {
            node.removeFromParent()
            node.name = ""
        }
    }
    
    func createNextLevel() {
        for node in self.children {
            if let _: Asteroid = node as? Asteroid {
                node.removeFromParent()
            }
        }
        
        level += 1
        maxAsteroid = level > 4 ? 11 : 2 + (level * 2)
        totalAsteroidsCreatedThisLevel = Double(maxAsteroid * 7)
        totalAsteroidsDestoryedThisLevel = 0
        totalAsteroids = 0
        enemyTimer = 100000
        lblNextLevel?.isHidden = false
        player.removeFromParent()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.lblNextLevel?.isHidden = true
            self.createPlayer(atX: self.frame.width / 2, atY: self.frame.height / 2)
            self.enemyTimer = Double.random(in: 1800...7200)
            for _ in 1...self.maxAsteroid {
                let randomX: CGFloat = CGFloat.random(in: 0...2048)
                let randomY: CGFloat = CGFloat.random(in: 0...1636)
                let asteroid: Asteroid = Asteroid(imageNamed: "asteroid1")
                asteroid.createAsteroid(atX: randomX, atY: randomY, withWidth: 240, withHeight: 240, withName: "asteroid-large")
                self.addChild(asteroid)
                self.totalAsteroids += 1
            }
        }
    }
}
