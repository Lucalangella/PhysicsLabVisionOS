import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var boxEntity: ModelEntity?
    
    var body: some View {
        RealityView { content in
            // --- 1. SETUP SCENE ---
            let floor = ModelEntity(
                mesh: .generatePlane(width: 4.0, depth: 4.0),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.5), isMetallic: false)]
            )
            floor.position = [0, 0, -2.0]
            floor.generateCollisionShapes(recursive: false)
            floor.components.set(PhysicsBodyComponent(mode: .static))
            content.add(floor)
            
            let box = ModelEntity(
                mesh: .generateBox(size: 0.3),
                materials: [SimpleMaterial(color: .red, isMetallic: false)]
            )
            box.position = [0, 1.5, -2.0]
            box.generateCollisionShapes(recursive: false)
            
            box.components.set(InputTargetComponent(allowedInputTypes: .all))
            
            let material = PhysicsMaterialResource.generate(
                staticFriction: appModel.staticFriction,
                dynamicFriction: appModel.dynamicFriction,
                restitution: appModel.restitution
            )
            var physicsBody = PhysicsBodyComponent(
                massProperties: .init(mass: appModel.mass),
                material: material,
                mode: appModel.selectedMode.rkMode
            )
            physicsBody.linearDamping = appModel.linearDamping
            box.components.set(physicsBody)
            
            content.add(box)
            self.boxEntity = box
            
            // --- 2. SUBSCRIBE TO UPDATES ---
            _ = content.subscribe(to: SceneEvents.Update.self) { event in
                guard let box = boxEntity,
                      let motion = box.components[PhysicsMotionComponent.self] else { return }
                
                let velocity = motion.linearVelocity
                let speed = length(velocity)
                appModel.currentSpeed = speed
            }
            
        } update: { content in }
        
        // --- 3. GESTURE WITH DEBUGGING ---
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    
                    // DEBUG: Report state
                    appModel.isDragging = true
                    
                    if var body = entity.components[PhysicsBodyComponent.self] {
                        body.mode = .kinematic
                        entity.components.set(body)
                    }
                    
                    var newPos = value.convert(value.location3D, from: .local, to: entity.parent!)
                    if newPos.y < 0.16 { newPos.y = 0.16 } // Floor Safety
                    entity.position = newPos
                    
                    entity.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
                }
                .onEnded { value in
                    let entity = value.entity
                    
                    // DEBUG: Report state
                    appModel.isDragging = false
                    
                    if var body = entity.components[PhysicsBodyComponent.self] {
                        body.mode = appModel.selectedMode.rkMode
                        entity.components.set(body)
                    }
                    
                    if appModel.selectedMode == .dynamic {
                        let currentPos = value.location3D
                        let predictedPos = value.predictedEndLocation3D
                        
                        let deltaX = Float(predictedPos.x - currentPos.x)
                        let deltaY = Float(predictedPos.y - currentPos.y)
                        let deltaZ = Float(predictedPos.z - currentPos.z)
                        
                        // DEBUG: Use the custom strength from the Dashboard
                        let strength = appModel.throwStrength
                        
                        var throwVel = SIMD3<Float>(deltaX * strength, deltaY * strength, deltaZ * strength)
                        
                        // Clamp max speed
                        if length(throwVel) > 20.0 {
                            throwVel = normalize(throwVel) * 20.0
                        }
                        
                        // DEBUG: Update the last vector so we can see it in the dashboard
                        appModel.lastThrowVector = String(format: "%.1f, %.1f, %.1f", throwVel.x, throwVel.y, throwVel.z)
                        
                        var motion = PhysicsMotionComponent()
                        motion.linearVelocity = throwVel
                        motion.angularVelocity = [Float.random(in: -3...3), Float.random(in: -3...3), Float.random(in: -3...3)]
                        entity.components.set(motion)
                    }
                }
        )
        // --- EVENT HANDLERS ---
        .onChange(of: appModel.resetSignal) {
            guard let box = boxEntity else { return }
            box.position = [0, 1.5, -2.0]
            box.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
            // Reset debug text
            appModel.lastThrowVector = "0.0, 0.0, 0.0"
        }
        // REMOVED: .onChange(of: appModel.impulseSignal)
        .onChange(of: [appModel.mass, appModel.restitution, appModel.dynamicFriction, appModel.staticFriction, appModel.linearDamping] as [Float]) {
            updatePhysicsProperties()
        }
        .onChange(of: appModel.selectedMode) {
            updatePhysicsProperties()
        }
    }
    
    func updatePhysicsProperties() {
        guard let box = boxEntity else { return }
        
        let newMaterial = PhysicsMaterialResource.generate(
            staticFriction: appModel.staticFriction,
            dynamicFriction: appModel.dynamicFriction,
            restitution: appModel.restitution
        )
        
        var bodyComponent = box.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent()
        bodyComponent.massProperties.mass = appModel.mass
        bodyComponent.material = newMaterial
        bodyComponent.mode = appModel.selectedMode.rkMode
        bodyComponent.linearDamping = appModel.linearDamping
        box.components.set(bodyComponent)
        
        switch appModel.selectedMode {
        case .dynamic: break
        case .staticMode:
            box.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
        case .kinematic:
            let spinSpeed: Float = 1.0
            box.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: [0, spinSpeed, 0]))
        }
    }
}
