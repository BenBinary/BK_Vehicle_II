//
//  ViewController.swift
//  BK_LavaIsOnTheFloor
//
//  Created by Benedikt Kurz on 07.05.19.
//  Copyright © 2019 Benedikt Kurz. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()


    
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        
        self.configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        self.setUpAccelerometer()
        self.setUpAccelerometer()
        self.sceneView.showsStatistics = true
        

    }
    
    @IBAction func addCar(_ sender: Any) {
        
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        let scene = SCNScene(named: "car.scn")
        let chassis = (scene!.rootNode.childNode(withName: "chassis", recursively: false))
        
        chassis!.position = currentPositionOfCamera
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis!, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        //car.physicsBody = body
        chassis?.physicsBody = body
        var wheels = [SCNPhysicsVehicleWheel]()
        
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: chassis!.childNode(withName: "rearLeftParent", recursively: false)!)
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: chassis!.childNode(withName: "frontRightParent", recursively: false)!)
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: chassis!.childNode(withName: "rearLeftParent", recursively: false)!)
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: chassis!.childNode(withName: "rearRightParent", recursively: false)!)
        
        wheels.append(v_rearLeftWheel)
        wheels.append(v_rearRightWheel)
        wheels.append(v_frontLeftWheel)
        wheels.append(v_frontRightWheel)
        
        
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassis!.physicsBody!, wheels: wheels)
        self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        self.sceneView.scene.rootNode.addChildNode(chassis!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
   
    }
    
    
    // Sobald ein neuer Punkt hinzugefügt wurde
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("new flat surface detectet, new AR - Plane Anchor added")
        let lavaNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)
        // self.sceneView.scene.rootNode.addChildNode(lavaNode)
        
        
    }
    
    
    // Sobald es ein Update für einen Anchor gibt
    // Node: Hier wird horizontal, die ARKit detected hat
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let lavaNode = createConcrete(planeAnchor: planeAnchor)
        
        node.addChildNode(lavaNode)
        
        print("updating the floors anchor ...")
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
        print("Simulationg Physics")
        
    }
    
    
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        concreteNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        concreteNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        
        
        return concreteNode
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        guard let _ = anchor as? ARPlaneAnchor else { return }
        
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }


    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func setUpAccelerometer() {
        
        if motionManager.isAccelerometerAvailable {
            
            motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { (CMAccelerometerData, Error) in
                if let error = Error {
                    print(error.localizedDescription)
                    return
                }
                self.accelorometerDidChange(acceleration: CMAccelerometerData!.acceleration)
                })
            

        } else  {
            print("Acceleramtoer not available")
        }
 
    }
    
    func accelorometerDidChange(acceleration: CMAcceleration) {
        
    }
    

}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180 }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}
