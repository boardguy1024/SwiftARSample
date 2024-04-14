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
    var car: Car = Car()
    
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
    
    @objc
    private func tapped(recognizer: UIGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let touchLocation = recognizer.location(in: sceneView)
        
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        
        guard let firstResult = sceneView.session.raycast(query).first else { return }
        
        self.car.position = SCNVector3(firstResult.worldTransform.columns.3.x,
                                  firstResult.worldTransform.columns.3.y,
                                  firstResult.worldTransform.columns.3.z)
        
        self.sceneView.scene.rootNode.addChildNode(self.car)
    }
    
    private func setupRemoteController() {
        let screenSize = UIScreen.main.bounds.size
        let leftButton = GameButton(frame: .init(x: 0, y: screenSize.height - 70, width: 100, height: 50)) { [weak self] in
            self?.car.turnLeft()
        }
        leftButton.setTitle("Left", for: .normal)
        
        self.sceneView.addSubview(leftButton)
        
        let rightButton = GameButton(frame: .init(x: screenSize.width - 100, y: screenSize.height - 70, width: 100, height: 50)) { [weak self] in
            self?.car.turnRight()
        }
        rightButton.setTitle("Right", for: .normal)
        
        self.sceneView.addSubview(rightButton)
        
        let acceleratorButton = GameButton(frame: .init(x: 120, y: screenSize.height - 70, width: 60, height: 20)) { [weak self] in
            self?.car.accelerate()
        }
        acceleratorButton.backgroundColor = .red
        acceleratorButton.layer.cornerRadius = 10.0
        acceleratorButton.layer.masksToBounds = true
        self.sceneView.addSubview(acceleratorButton)
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
