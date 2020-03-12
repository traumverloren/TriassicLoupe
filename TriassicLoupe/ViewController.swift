/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import SceneKit
import ARKit
import CoreMedia

class ViewController: UIViewController {
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var instructionLabel: UILabel!

  private var worldConfiguration: ARWorldTrackingConfiguration?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self

    // Uncomment to show statistics such as fps and timing information
    //sceneView.showsStatistics = true

    let scene = SCNScene()
    sceneView.scene = scene
    
    setupObjectDetection()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let configuration = worldConfiguration {
      sceneView.debugOptions = .showFeaturePoints
      sceneView.session.run(configuration)
    }
    
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    sceneView.session.pause()
  }

  private func setupObjectDetection() {
    worldConfiguration = ARWorldTrackingConfiguration()

    guard let referenceObjects = ARReferenceObject.referenceObjects(
      inGroupNamed: "AR Objects", bundle: nil) else {
      fatalError("Missing expected asset catalog resources.")
    }

    worldConfiguration?.detectionObjects = referenceObjects
  }

}

extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didFailWithError error: Error) {
    guard
      let error = error as? ARError,
      let code = ARError.Code(rawValue: error.errorCode)
      else { return }
    instructionLabel.isHidden = false
    switch code {
    case .cameraUnauthorized:
      instructionLabel.text = "Camera tracking is not available. Please check your camera permissions."
    default:
      instructionLabel.text = "Error starting ARKit. Please fix the app and relaunch."
    }
  }

  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    switch camera.trackingState {
    case .limited(let reason):
      instructionLabel.isHidden = false
      switch reason {
      case .excessiveMotion:
        instructionLabel.text = "Too much motion! Slow down."
      case .initializing, .relocalizing:
        instructionLabel.text = "ARKit is doing it's thing. Move around slowly for a bit while it warms up."
      case .insufficientFeatures:
        instructionLabel.text = "Not enough features detected, try moving around a bit more or turning on the lights."
      }
    case .normal:
      instructionLabel.text = "Point the camera at a Wilbur."
    case .notAvailable:
      instructionLabel.isHidden = false
      instructionLabel.text = "Camera tracking is not available."
    }
  }
}

extension ViewController: ARSCNViewDelegate {

  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    DispatchQueue.main.async { self.instructionLabel.isHidden = true }
    if let objectAnchor = anchor as? ARObjectAnchor {
      handleFoundObject(objectAnchor, node)
    }
  }

  private func handleFoundObject(_ objectAnchor: ARObjectAnchor, _ node: SCNNode) {
    // 1
    let name = objectAnchor.referenceObject.name!
    print("You found a \(name) object")

    // 2
    let text = SCNText(string: name, extrusionDepth: 0.1)
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.red
    text.materials = [material]
    text.font = UIFont(name: "Helvetica", size: 1)
    
    let textNode = SCNNode()
    textNode.scale = SCNVector3(x: 0.02, y: 0.01, z: 0.01)
    textNode.geometry = text
    textNode.position = node.position
    textNode.position.y += 0.05
    textNode.position.x -= 0.018
    node.addChildNode(textNode)
  }
}

