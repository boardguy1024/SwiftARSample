//
//  TargetAppViewController.swift
//  HelloAR
//
//  Created by paku on 2024/03/19.
//

import UIKit
import ARKit

enum BoxBodyType: Int {
    // 明示的に設定しないと衝突は　　発生しない
    case bullet = 1
    case barrier = 2
}

// 発砲してターケットを当てると色が緑になるサンプルコード
class TargetAppViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    private var lastContactNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
       
        sceneView.scene.physicsWorld.contactDelegate = self
        
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        
        let box1Node = SCNNode(geometry: box)
        box1Node.name = "Barrier1"
        box1Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box1Node.physicsBody?.categoryBitMask = BoxBodyType.barrier.rawValue
        box1Node.position = SCNVector3(-1, 0.0, -1.5)
        
        let box2Node = SCNNode(geometry: box)
        box2Node.name = "Barrier2"
        box2Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box2Node.physicsBody?.categoryBitMask = BoxBodyType.barrier.rawValue
        box2Node.position = SCNVector3(0, 0.0, -1)
        
        let box3Node = SCNNode(geometry: box)
        box3Node.name = "Barrier3"
        box3Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box3Node.physicsBody?.categoryBitMask = BoxBodyType.barrier.rawValue
        box3Node.position = SCNVector3(1, 0.0, -1.5)
        
        sceneView.scene.rootNode.addChildNode(box1Node)
        sceneView.scene.rootNode.addChildNode(box2Node)
        sceneView.scene.rootNode.addChildNode(box3Node)

        registerGesture()
    }
    
    private func registerGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gesture)
    }
    
    @objc
    private func tapped(recognizer: UIGestureRecognizer) {
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        
        // matrix_identity_float4x4は
        // x 1 0 0 0
        // y 0 1 0 0
        // z 0 0 1 0
        // w 0 0 0 1
        // 4x4行列を初期化
        var translation = matrix_identity_float4x4
        // z方向に -30cm移動させる
        translation.columns.3.z = -0.3
        
        // 発射するboxを生成
        let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        box.materials = [material]
        
        let boxNode = SCNNode(geometry: box)
        // physicsWorld(_ world:,didBegin:)で使うためにnameを設定
        boxNode.name = "Bullet"
        // simdTransform: 位置、回転、スケールの変換をーつの行列として表現
        // simd = Single Instruction Multiple Data : 一つの命令で複数のデータを同時に処理する能力を指す
        // つまり、nodeの位置、回転、スケールの変換を行いたい場合、これを使えば良い
        
        // matrix_multiply(a,b) は行列の乗算
        // 現在のカメラの位置から指定した方向と距離(tranlation)に配置させる
        // つまり、タップしたら、カメラの真ん中から z-30cmの位置に boxが位置される
        boxNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)

        // .dynamicを設定すると重力により下へ落ちる
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.categoryBitMask = BoxBodyType.bullet.rawValue
        boxNode.physicsBody?.collisionBitMask = BoxBodyType.barrier.rawValue
        boxNode.physicsBody?.contactTestBitMask = BoxBodyType.barrier.rawValue
        //重力による影響を falseに設定すると nodeは落ちない
        boxNode.physicsBody?.isAffectedByGravity = false
        
        let forceVector = SCNVector3(boxNode.worldFront.x * 2, boxNode.worldFront.y * 2, boxNode.worldFront.z * 2)

        boxNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension TargetAppViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
}

extension TargetAppViewController: SCNPhysicsContactDelegate {
    // boxNode.physicsBody?.contactTestBitMask = BoxBodyType.barrier.rawValueを設定しているので
    // bulletがbarrierとContactしたときに呼ばれる
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        var contactNode: SCNNode?

        if contact.nodeA.name == "Bullet" {
            // bulletとcontactした nodeBをtargetにする
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        // 一度色を変更したnodeは 以下の処理を回避する
        if self.lastContactNode != nil && self.lastContactNode == contactNode {
            return
        }
        
        self.lastContactNode = contactNode
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        
        // barrier1,2,3には同じ box(geometry)が設定しているため、すべてのboxが対象になってしまう
        // self.lastContactNode?.geometry?.materials = [material]
    
        // 新しくboxを生成して割り当てる必要がある
        let newBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        newBox.materials = [material]

        self.lastContactNode?.geometry = newBox
    }
}
 
