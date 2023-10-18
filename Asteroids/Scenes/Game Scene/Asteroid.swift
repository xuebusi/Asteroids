//
//  Asteroid.swift
//  Asteroids
//
//  Created by shiyanjun on 2023/10/13.
//

import SpriteKit

class Asteroid: SKSpriteNode {
    // MARK: - PROPERTIES
    var xMovement: CGFloat = 0
    var yMovement: CGFloat = 0
    
    func createAsteroid(atX x: CGFloat, atY y: CGFloat, withWidth width: Int, withHeight height: Int, withName name: String) {
        xMovement = CGFloat.random(in: -2...4)
        yMovement = CGFloat.random(in: -2...4)
        
        self.size = CGSize(width: width, height: height)
        self.position = CGPoint(x: x, y: y)
        self.zPosition = 0
        self.name = name
        
        self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = true
        
        self.physicsBody?.categoryBitMask = CollisionCategory.asteroid.rawValue
        self.physicsBody?.collisionBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue | CollisionCategory.player.rawValue | CollisionCategory.playerBullet.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.enemy.rawValue | CollisionCategory.enemyBullet.rawValue | CollisionCategory.player.rawValue | CollisionCategory.playerBullet.rawValue
    }
    
    func moveAsteroid() {
        self.position = CGPoint(x: self.position.x + xMovement, y: self.position.y + yMovement)
    }
}
