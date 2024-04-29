//
//  ViewController.swift
//  ARDice
//
//  Created by YouUp Lee on 4/29/24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  // MARK: - Property
  
  @IBOutlet var sceneView: ARSCNView!
  
  private var diceArray = [SCNNode]()
  
  
  
  // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set the view's delegate
    self.sceneView.delegate = self
    
    self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    
    // Show statistics such as fps and timing information
//    sceneView.showsStatistics = true
    
    // Create a new scene
//    let scene = SCNScene(named: "art.scnassets/ship.scn")!
    
    // Set the scene to the view
//    self.sceneView.scene = scene
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // 디바이스에 따라 환경 설정
    if ARWorldTrackingConfiguration.isSupported {
      // Create a session configuration
      let configuration = ARWorldTrackingConfiguration()
      
      configuration.planeDetection = .horizontal
      
      // Run the view's session
      self.sceneView.session.run(configuration)
      
    } else {
      // Create a session configuration
      let configuration = AROrientationTrackingConfiguration()
      
      // Run the view's session
      self.sceneView.session.run(configuration)
    }
    
    self.sceneView.autoenablesDefaultLighting = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    self.sceneView.session.pause()
  }
  
  
  
  // MARK: - Touch
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchLocation = touch.location(in: self.sceneView)
    
    guard let query = self.sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .any) else { return }
    let results = self.sceneView.session.raycast(query)
    self.addDice(results)
  }
  
  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    self.rollAll()
  }
  
  
  
  // MARK: - Action
  
  @IBAction func clearDidTap(_ sender: UIButton) {
    let items = self.sceneView.scene.rootNode.childNodes
    items.forEach { $0.removeFromParentNode() }
  }
  
  @IBAction func runDidTap(_ sender: UIButton) {
    self.rollAll()
  }
  
  @IBAction func cubeDidTap(_ sender: UIButton) {
    let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.red
    cube.materials = [material]
    let node = SCNNode()
    node.position = SCNVector3(x: 0, y: -0.1, z: -0.5)
    node.geometry = cube
    self.sceneView.scene.rootNode.addChildNode(node)
  }
  
  @IBAction func diceDidTap(_ sender: UIButton) {
    let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
    guard let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) else { return }
    diceNode.position = SCNVector3(x: 0, y: 0, z: -0.1)
    self.sceneView.scene.rootNode.addChildNode(diceNode)
  }
  
  @IBAction func sunDidTap(_ sender: UIButton) {
    let sun = SCNSphere(radius: 0.2)
    let material = SCNMaterial()
    material.diffuse.contents = UIImage(named: "art.scnassets/sun.jpg")
    sun.materials = [material]
    let node = SCNNode()
    node.position = SCNVector3(x: 0, y: -0.1, z: -0.5)
    node.geometry = sun
    self.sceneView.scene.rootNode.addChildNode(node)
  }
  
  
  
  // MARK: - Interface
  
  private func addDice(_ results: [ARRaycastResult]) {
    guard let hitResult = results.first,
          let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn"),
          let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true)
    else { return }
    
    diceNode.position = SCNVector3(
      x: hitResult.worldTransform.columns.3.x,
      y: hitResult.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
      z: hitResult.worldTransform.columns.3.z
    )
    
    self.diceArray.append(diceNode)
    
    self.sceneView.scene.rootNode.addChildNode(diceNode)
  }
  
  private func rollAll() {
    guard !self.diceArray.isEmpty else { return }
    self.diceArray.forEach { self.roll($0) }
  }
  
  private func roll(_ dice: SCNNode) {
    let randomX: CGFloat = CGFloat(arc4random_uniform(4) + 1) * CGFloat(Float.pi / 2)
    let randomZ: CGFloat = CGFloat(arc4random_uniform(4) + 1) * CGFloat(Float.pi / 2)
    let action = SCNAction.rotateBy(
      x: randomX * 3,
      y: 0,
      z: randomZ * 3,
      duration: 0.5
    )
    dice.runAction(action)
  }
  
  private func createPlane(_ planeAncher: ARPlaneAnchor) -> SCNNode {
    let planeNode = SCNNode()
    planeNode.position = SCNVector3(x: planeAncher.center.x, y: 0, z: planeAncher.center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
    
    let gridMaterial = SCNMaterial()
    gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
    
    let plane = SCNPlane(width: CGFloat(planeAncher.planeExtent.width), height: CGFloat(planeAncher.planeExtent.height))
    plane.materials = [gridMaterial]
    
    planeNode.geometry = plane
    
    return planeNode
  }
  
  
  
  // MARK: - ARSCNViewDelegate
  
  func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAncher = anchor as? ARPlaneAnchor else { return }
    let planeNode = self.createPlane(planeAncher)
    node.addChildNode(planeNode)
  }
}
