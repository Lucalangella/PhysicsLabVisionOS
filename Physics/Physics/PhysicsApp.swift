import SwiftUI

@main
struct PhysicsLabApp: App {
    @State private var appModel = AppModel()
    
    // Note: We don't necessarily need 'openImmersiveSpace' if we are just using a Volume,
    // but we keep it here in case you want to expand later.
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    var body: some Scene {
        WindowGroup {
            PhysicsControlView()
                .environment(appModel)
                .task {
                    // In a Volumetric app, we usually don't open an ImmersiveSpace immediately,
                    // because the Volume *is* the space.
                    // But if you want the "World" physics, we can keep this.
                    if appModel.immersiveSpaceState == .closed {
                        appModel.immersiveSpaceState = .inTransition
                        await openImmersiveSpace(id: "PhysicsSpace")
                        appModel.immersiveSpaceState = .open
                    }
                }
        }
        // --- 1. SET STYLE TO VOLUMETRIC ---
        .windowStyle(.volumetric)
        // --- 2. SET SIZE (Meters) ---
        // Width: 0.5m, Height: 1.1m (matches your 1100pt height), Depth: 0.5m
        .defaultSize(width: 0.5, height: 1.1, depth: 0.5, in: .meters)
        
        // The Immersive Space (The room around you)
        ImmersiveSpace(id: "PhysicsSpace") {
            ImmersiveView()
                .environment(appModel)
        }
    }
}
