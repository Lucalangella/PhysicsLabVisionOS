import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    // Scene References
    @State private var objectEntity: ModelEntity?
    @State private var rootEntity: Entity?
    @State private var traceRoot: Entity?
    @State private var rampEntity: ModelEntity?
    
    // Logic State
    @State private var lastMarkerPosition: SIMD3<Float>? = nil
    
    var body: some View {
        RealityView { content in
            // --- 1. SETUP SCENE ---
            let root = Entity()
            root.name = "Root"
            
            var physSim = PhysicsSimulationComponent()
            physSim.gravity = [0, -9.8, 0]
            root.components.set(physSim)
            
            content.add(root)
            self.rootEntity = root
            
            let traces = Entity()
            traces.name = "TraceRoot"
            root.addChild(traces)
            self.traceRoot = traces
            
            let floor = ModelEntity(
                mesh: .generatePlane(width: 4.0, depth: 4.0),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.5), isMetallic: false)]
            )
            floor.position = [0, 0, -2.0]
            floor.generateCollisionShapes(recursive: false)
            floor.components.set(PhysicsBodyComponent(mode: .static))
            root.addChild(floor)
            
            // ---------------------------------------------------------
            // 1. SETUP RAMP (Right-Angled Wedge)
            // ---------------------------------------------------------
            var descriptor = MeshDescriptor(name: "wedge")
            
            // Dimensions
            let width: Float = 1.0
            let height: Float = 0.5
            let depth: Float = 1.0 // Length of the ramp
            
            // Coordinates
            let frontZ: Float = depth / 2
            let backZ: Float = -depth / 2
            let topY: Float = height / 2
            let bottomY: Float = -height / 2
            let leftX: Float = -width / 2
            let rightX: Float = width / 2
            
            descriptor.positions = MeshBuffers.Positions([
                // Front Face Vertices (0, 1, 2)
                // We align Top X with Left X to make it a right-angled wedge
                [leftX, topY, frontZ],      // 0: Top Left (High Point)
                [leftX, bottomY, frontZ],   // 1: Bottom Left (Corner)
                [rightX, bottomY, frontZ],  // 2: Bottom Right (End of Slope)
                
                // Back Face Vertices (3, 4, 5)
                [leftX, topY, backZ],       // 3: Top Left (High Point)
                [leftX, bottomY, backZ],    // 4: Bottom Left (Corner)
                [rightX, bottomY, backZ]    // 5: Bottom Right (End of Slope)
            ])
            
            descriptor.primitives = .triangles([
                // Front Face
                0, 1, 2,
                
                // Back Face (Clockwise)
                3, 5, 4,
                
                // Vertical Back Wall (Rectangle formed by 0-1 and 3-4)
                0, 4, 1,
                0, 3, 4,
                
                // Sloped Face (Hypotenuse Rectangle)
                0, 2, 5,
                0, 5, 3,
                
                // Bottom Face
                1, 4, 5,
                1, 5, 2
            ])
            
            // Generate Mesh
            if let rampMesh = try? MeshResource.generate(from: [descriptor]) {
                let ramp = ModelEntity(
                    mesh: rampMesh,
                    materials: [SimpleMaterial(color: .cyan.withAlphaComponent(0.8), isMetallic: false)]
                )
                
                // Position: Moved back and raised slightly to sit on the floor
                // Note: The mesh center is (0,0,0), so 'bottomY' is -0.25.
                // To put it on floor (y=0), we raise it by 0.25 (height/2).
                ramp.position = [0.0, 0.25, -2.0]
                
                // Physics: Static (won't move) but objects can hit it
                ramp.generateCollisionShapes(recursive: false)
                ramp.components.set(PhysicsBodyComponent(mode: .static))
                
                // Initial visibility state
                ramp.isEnabled = appModel.showRamp
                
                root.addChild(ramp)
                self.rampEntity = ramp
            }
            // ---------------------------------------------------------

            
            // --- CREATE INITIAL OBJECT ---
            let object = ModelEntity() // Empty initially
            object.position = [0, 1.5, -2.0]
            
            // Basic Components
            object.components.set(InputTargetComponent(allowedInputTypes: .all))
            
            // Initial Physics Setup
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
            object.components.set(physicsBody)
            
            root.addChild(object)
            self.objectEntity = object
            
            // Apply the initial shape
            updateShape()
            
            // --- 2. SUBSCRIBE TO UPDATES ---
            _ = content.subscribe(to: SceneEvents.Update.self) { event in
                guard let obj = objectEntity,
                      let motion = obj.components[PhysicsMotionComponent.self] else { return }
                
                // 1. Update Speed
                let velocity = motion.linearVelocity
                let speed = length(velocity)
                appModel.currentSpeed = speed
                
                // 2. Update Gravity
                if let root = rootEntity,
                   var physSim = root.components[PhysicsSimulationComponent.self] {
                    physSim.gravity = [0, appModel.gravity, 0]
                    root.components.set(physSim)
                }
                
                // 3. Update Path Plotter
                if appModel.showPath {
                    let currentPos = obj.position(relativeTo: nil)
                    
                    if let lastPos = lastMarkerPosition {
                        let distance = length(currentPos - lastPos)
                        if distance > 0.05 { // 5 cm threshold
                            addPathMarker(at: currentPos)
                            lastMarkerPosition = currentPos
                        }
                    } else {
                        lastMarkerPosition = currentPos
                    }
                }
            }
            
        } update: { content in }
        
        // --- 3. GESTURE ---
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    appModel.isDragging = true
                    
                    // Temporarily make kinematic to control position
                    if var body = entity.components[PhysicsBodyComponent.self] {
                        body.mode = .kinematic
                        entity.components.set(body)
                    }
                    
                    // Constrain movement to floor height
                    var newPos = value.convert(value.location3D, from: .local, to: entity.parent!)
                    if newPos.y < 0.16 { newPos.y = 0.16 }
                    entity.position = newPos
                    
                    // Reset velocity while dragging
                    entity.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
                }
                .onEnded { value in
                    let entity = value.entity
                    appModel.isDragging = false
                    
                    // Restore original physics mode
                    if var body = entity.components[PhysicsBodyComponent.self] {
                        body.mode = appModel.selectedMode.rkMode
                        entity.components.set(body)
                    }
                    
                    // Stop movement on drop
                    if appModel.selectedMode == .dynamic {
                        var motion = PhysicsMotionComponent()
                        motion.linearVelocity = .zero
                        motion.angularVelocity = .zero
                        entity.components.set(motion)
                    }
                }
        )
        // --- EVENT HANDLERS ---
        .onChange(of: appModel.resetSignal) {
            guard let obj = objectEntity else { return }
            obj.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
            obj.position = [0, 1.5, -2.0]
            
            traceRoot?.children.removeAll()
            lastMarkerPosition = nil
        }
        .onChange(of: [appModel.mass, appModel.restitution, appModel.dynamicFriction, appModel.staticFriction, appModel.linearDamping] as [Float]) {
            updatePhysicsProperties()
        }
        .onChange(of: appModel.selectedMode) {
            updatePhysicsProperties()
        }
        .onChange(of: appModel.showPath) {
            if !appModel.showPath {
                traceRoot?.children.removeAll()
                lastMarkerPosition = nil
            }
        }
        .onChange(of: appModel.selectedShape) {
            updateShape()
        }
        // Handle Ramp Visibility
        .onChange(of: appModel.showRamp) {
            rampEntity?.isEnabled = appModel.showRamp
        }
        // Handle Ramp Rotation
        .onChange(of: appModel.rampAngle) {
            guard let ramp = rampEntity else { return }
            
            let radians = appModel.rampAngle * (Float.pi / 180.0)
            
            // Standard Rotation around X-axis
            ramp.transform.rotation = simd_quatf(angle: radians, axis: [1, 0, 0])
        }
    }
    
    // MARK: - Updates
    func updateShape() {
        guard let obj = objectEntity else { return }
        
        let newMesh: MeshResource
        let newMaterial: SimpleMaterial
        
        switch appModel.selectedShape {
        case .box:
            newMesh = .generateBox(size: 0.3)
            newMaterial = SimpleMaterial(color: .red, isMetallic: false)
        case .sphere:
            newMesh = .generateSphere(radius: 0.15)
            newMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        case .cylinder:
            newMesh = .generateCylinder(height: 0.3, radius: 0.15)
            newMaterial = SimpleMaterial(color: .green, isMetallic: false)
        }
        
        obj.model = ModelComponent(mesh: newMesh, materials: [newMaterial])
        obj.generateCollisionShapes(recursive: false)
    }
    
    func updatePhysicsProperties() {
        guard let obj = objectEntity else { return }
        
        let newMaterial = PhysicsMaterialResource.generate(
            staticFriction: appModel.staticFriction,
            dynamicFriction: appModel.dynamicFriction,
            restitution: appModel.restitution
        )
        
        var bodyComponent = obj.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent()
        bodyComponent.massProperties.mass = appModel.mass
        bodyComponent.material = newMaterial
        bodyComponent.mode = appModel.selectedMode.rkMode
        bodyComponent.linearDamping = appModel.linearDamping
        obj.components.set(bodyComponent)
        
        switch appModel.selectedMode {
        case .dynamic: break
        case .staticMode:
            obj.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: .zero))
        case .kinematic:
            let spinSpeed: Float = 1.0
            obj.components.set(PhysicsMotionComponent(linearVelocity: .zero, angularVelocity: [0, spinSpeed, 0]))
        }
    }
    
    // MARK: - Path Plotter
    private func addPathMarker(at position: SIMD3<Float>) {
        guard let parent = traceRoot else { return }
        
        let mesh = MeshResource.generateSphere(radius: 0.005)
        let material = UnlitMaterial(color: .yellow)
        let marker = ModelEntity(mesh: mesh, materials: [material])
        
        marker.position = position
        
        parent.addChild(marker)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
//
//#Preview("Ramp Visualization", immersionStyle: .mixed) {
//    let model = AppModel()
//    model.showRamp = true
//    model.rampAngle = 30.0
//    
//    return ImmersiveView()
//        .environment(model)
//}
