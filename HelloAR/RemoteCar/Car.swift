//
//  Car.swift
//  HelloAR
//
//  Created by paku on 2024/04/14.
//

import ARKit
import UIKit

class Car: SCNNode {
    
    var carNode: SCNNode?
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        let carScene = SCNScene(named: "car.dae")
        let carNode = carScene?.rootNode.childNode(withName: "car", recursively: true)
        self.carNode = carNode
        self.addChildNode(carNode!)
        
        // add physics
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody?.categoryBitMask = BodyType.car.rawValue
        
    }
    
    func accelerate() {
        // -5 : z方向(全身)
        let force = simd_make_float4(0, 0, -5, 0)
        
        // presentation - animation中の状態、つまり画面上で表示されている状態の情報を表している。
        // つまり車の前の方向 -zにだけforceを加えたい場合、presentation.simdTransformをベースに forceをかける
        let rotatedForce = simd_mul(self.presentation.simdTransform, force)
        let vectorForce = SCNVector3(rotatedForce.x, rotatedForce.y, rotatedForce.z)
        self.physicsBody?.applyForce(vectorForce, asImpulse: false)
    }
    
    func turnRight() {
        self.physicsBody?.applyTorque(SCNVector4(0, 1, 0, -1), asImpulse: false)
    }
    
    func turnLeft() {
        self.physicsBody?.applyTorque(SCNVector4(0, 1, 0, 1), asImpulse: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
