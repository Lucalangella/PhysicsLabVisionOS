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
        // --- 1. SET STYLE TO AUTOMATIC (Standard Window) ---
        .windowStyle(.automatic)
        // --- 2. SET SIZE ---
        .defaultSize(width: 400, height: 800)
        
        // The Immersive Space (The room around you)
        ImmersiveSpace(id: "PhysicsSpace") {
            ImmersiveView()
                .environment(appModel)
        }
    }
}
