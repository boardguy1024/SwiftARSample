//
//  MeasurementViewController.swift
//  HelloAR
//
//  Created by paku on 2024/04/01.
//

import UIKit
import ARKit

class MeasurementViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!

    private var nodes: [SCNNode] = []
    private var isShowingDistance: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        registerGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addPlusLabel()
    }
    
    private func addPlusLabel() {
        let label = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 50))
        label.text = "+"
        label.textAlignment = .center
        label.textColor = .white
        label.center = self.sceneView.center
        self.sceneView.addSubview(label)
    }
    
    private func registerGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gesture)
    }
    
    @objc
    private func tapped(recognizer: UIGestureRecognizer) {
        
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        // touchしたlocationは使わない
        // let touchLocation = recognizer.location(in: sceneView)
        if let query = sceneView.raycastQuery(from: sceneView.center, allowing: .estimatedPlane, alignment: .horizontal) {
            
            let results = sceneView.session.raycast(query)
            
            if let firstResult = results.first {
                
                let sphere = SCNSphere(radius: 0.005)
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.red
                sphere.materials = [material]
                
                let node = SCNNode(geometry: sphere)
                node.position = SCNVector3(
                    firstResult.worldTransform.columns.3.x,
                    firstResult.worldTransform.columns.3.y,
                    firstResult.worldTransform.columns.3.z
                )
                
                sceneView.scene.rootNode.addChildNode(node)
                
                nodes.append(node)
                
                if nodes.count == 2, let first = nodes.first, let last = nodes.last {
                    // calculate distance
                    // ピタゴラス定義による(a2+b2=c2)で長さを計算
                    // vectorB - vectorAをして、(a2+b2=c2)によるc2を square.rootで算出
                    let position = SCNVector3Make(last.position.x - first.position.x,
                                                  last.position.y - first.position.y,
                                                  last.position.z - first.position.z)
                    let x_2t = position.x * position.x
                    let y_2t = position.y * position.y
                    let z_2t = position.z * position.z
                    let result = sqrt(x_2t + y_2t + z_2t)

                    print("result!: \(result * 100)cm")
                    
                    // 点2の間にテキストを表示するには a+b / 2
                    // M = (x1+x2)/2, (y1+y2)/2, (z1+z2)/2
                    let centerX = (first.position.x + last.position.x) / 2
                    let centerY = (first.position.y + last.position.y) / 2
                    let centerZ = (first.position.z + last.position.z) / 2
                    displayDistance(with: result, position: .init(centerX, centerY + 0.05, centerZ))
                    
                    isShowingDistance = true
                }
            }
        }
        
    }
    
    private func displayDistance(with distance: Float, position: SCNVector3) {
        
        let text = SCNText(string: "\(distance * 100)cm", extrusionDepth: 1.0)
        text.firstMaterial?.diffuse.contents = UIColor.black
        
        let textNode = SCNNode(geometry: text)
        textNode.position = position
        textNode.scale = .init(0.002, 0.002, 0.002)
        
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        // 水平の面を検知
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension MeasurementViewController: ARSCNViewDelegate {
}


