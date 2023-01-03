//
//  ViewController.swift
//  ARDicee
//
//  Created by Adam Yoneda on 2022/11/28.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var diceArray: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Lighting
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ARWorldTrackingConfiguration.isSupported {
            
            // Create a session configuration
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            
            // Run the view's session
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    //MARK: - Dice Rendering Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            // 2Dから3Dへ変換
            let result = sceneView.hitTest(touchLocation, options: nil)
            if let hitResult = result.first {
                // Call addDice method
                addDice(atLocation: hitResult)
            }
        }
    }
    
    func addDice(atLocation location: SCNHitTestResult) {
        // Create a new scene
        guard let diceScene = SCNScene(named: "artisan.scnassets/diceCollada.scn") else {
            fatalError()
        }
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            diceNode.position = SCNVector3(
                x: location.worldCoordinates.x,
                y: location.worldCoordinates.y + diceNode.boundingSphere.radius,
                z: location.worldCoordinates.z)
            // Add to diceArray
            diceArray.append(diceNode)
            // Add into sceneView
            sceneView.scene.rootNode.addChildNode(diceNode)
            // Run Roll method
            roll(dice: diceNode)
        }
    }
    
    func roll(dice: SCNNode) {
        // Generate random number
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
        // runAction(_:)
        dice.runAction(
            SCNAction.rotateBy(
                x: CGFloat(randomX * 5),
                y: 0,
                z: CGFloat(randomZ * 5),
                duration: 0.5)
        )
    }
    
    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    //MARK: - ARSCNViewDelegateMethod
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        // Add childNode into rootNode
        node.addChildNode(planeNode)
    }
    
    //MARK: - Plane Rendering Metohd
    
    func createPlane(withPlaneAnchor planeAnchor : ARPlaneAnchor) -> SCNNode{
        // Create SCNPlane
        let plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width),
                             height: CGFloat(planeAnchor.planeExtent.height))
        // Create Node
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        // Rotate 90 degree
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        // Give a material
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "artisan.scnassets/grid.png")
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
}
