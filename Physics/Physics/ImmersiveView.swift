import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var boxEntity: ModelEntity?
    @State private var speedText: String = "0.0 m/s" // Stores current speed
    
    var body: some View {
        RealityView { content, attachments in
            // --- 1. SETUP SCENE ---
            
            // Floor
            let floor = ModelEntity(
                mesh: .generatePlane(width: 4.0, depth: 4.0),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.5), isMetallic: false)]
            )
            floor.position = [0, 0, -2.0]
            floor.generateCollisionShapes(recursive: false)
            floor.components.set(PhysicsBodyComponent(mode: .static))
            content.add(floor)
            
            // Box
            let box = ModelEntity(
                mesh: .generateBox(size: 0.3),
                materials: [SimpleMaterial(color: .red, isMetallic: false)]
            )
            box.position = [0, 1.5, -2.0]
            box.generateCollisionShapes(recursive: false)
            
            // Physics
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
            
            // --- 2. ADD ATTACHMENT ---
            // Fetch the SwiftUI view we defined below (id: "speedLabel")
            if let attachmentEntity = attachments.entity(for: "speedLabel") {
                // Position it 25cm above the cube
                attachmentEntity.position = [0, 0.25, 0]
                // Make it a child of the box so it moves with it
                box.addChild(attachmentEntity)
            }
            
            // --- 3. SUBSCRIBE TO UPDATES (To calculate speed) ---
            // This runs every single frame (90 times a second)
            _ = content.subscribe(to: SceneEvents.Update.self) { event in
                guard let box = boxEntity,
                      let motion = box.components[PhysicsMotionComponent.self] else { return }
                
                // Calculate speed (magnitude of velocity vector)
                let velocity = motion.linearVelocity
                let speed = sqrt(velocity.x*velocity.x + velocity.y*velocity.y + velocity.z*velocity.z)
                
                // Update the state variable
                self.speedText = String(format: "%.1f m/s", speed)
            }
            
        } update: { content, attachments in
            // (Optional) Handle updates here if needed
        } attachments: {
            // --- 4. DEFINE THE SWIFTUI VIEW ---
            Attachment(id: "speedLabel") {
                Text(speedText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.black.opacity(0.7))
                    .cornerRadius(12)
                    // Make it always face the user (Billboard effect) is automatic for attachments usually,
                    // but keeping it simple here.
            }
        }
        // --- EVENT HANDLERS ---
        .onChange(of: appModel.resetSignal) {
            guard let box = boxEntity else { return }
            box.position = [0, 1.5, -2.0]
            box.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
        }
        .onChange(of: appModel.impulseSignal) {
            guard let box = boxEntity else { return }
            if appModel.selectedMode == .dynamic {
                let kickStrength: Float = 10.0 * appModel.mass
                box.applyLinearImpulse([0, 2.0, -kickStrength], relativeTo: nil)
            }
        }
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
        
        if appModel.selectedMode != .dynamic {
            box.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
        }
    }
}
