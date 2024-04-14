//
//  RemoteCarViewController.swift
//  HelloAR
//
//  Created by paku on 2024/04/09.
//

import UIKit
import ARKit

enum BodyType: Int {
    case box = 1
    case plane = 2
    case car = 3
}
class RemoteCarViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var planes = [OverlayPlane]()
    var carNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.delegate = self
        // self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showPhysicsShapes]
        
        setupRemoteController()
        registerGesture()
    }
    
    private func registerGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGesture)
    }
    
    private func addCar(position: SCNVector3) {
        let carScene = SCNScene(named: "car.dae")
        if let carNode = carScene?.rootNode.childNode(withName: "car", recursively: true) {
            carNode.position = position
            carNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            carNode.physicsBody?.categoryBitMask = BodyType.car.rawValue
            self.carNode = carNode
            self.sceneView.scene.rootNode.addChildNode(carNode)
        }
    }
    
    @objc
    private func tapped(recognizer: UIGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let touchLocation = recognizer.location(in: sceneView)
        
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        
        guard let firstResult = sceneView.session.raycast(query).first else { return }
        
        let position = SCNVector3(firstResult.worldTransform.columns.3.x,
                                  firstResult.worldTransform.columns.3.y + 1,
                                  firstResult.worldTransform.columns.3.z)
        addCar(position: position)
    }
    
    private func setupRemoteController() {
        let screenSize = UIScreen.main.bounds.size
        let leftButton = GameButton(frame: .init(x: 0, y: screenSize.height - 70, width: 100, height: 50)) { [weak self] in
            self?.turnLeft()
        }
        leftButton.setTitle("Left", for: .normal)
        
        self.sceneView.addSubview(leftButton)
        
        let rightButton = GameButton(frame: .init(x: screenSize.width - 100, y: screenSize.height - 70, width: 100, height: 50)) { [weak self] in
            self?.turnRight()
        }
        rightButton.setTitle("Right", for: .normal)
        
        self.sceneView.addSubview(rightButton)
        
        let acceleratorButton = GameButton(frame: .init(x: 120, y: screenSize.height - 70, width: 60, height: 20)) {
            print("acceleratorButton tapped")
        }
        acceleratorButton.backgroundColor = .red
        acceleratorButton.layer.cornerRadius = 10.0
        acceleratorButton.layer.masksToBounds = true
        self.sceneView.addSubview(acceleratorButton)
    }
    
    private func turnLeft() {
        // Torgue - トルク : 物体を回転させる量・回転力
        // y軸を中心に 回転
        // w: クォータニオンの回転におけるスカラー
        self.carNode.physicsBody?.applyTorque(.init(0, 1, 0, 1), asImpulse: false)
    }
    
    private func turnRight() {
        self.carNode.physicsBody?.applyTorque(.init(0, 1, 0, -1), asImpulse: false)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
}

extension RemoteCarViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        let plane = OverlayPlane(anchor: anchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        
        if let plane = self.planes.filter({ $0.anchor.identifier == anchor.identifier }).first {
            plane.update(anchor: anchor)
        } 
    }
}
