//
//  ToggleImmersiveSpaceButton.swift
//  Physics
//
//  Created by Luca Langella 1 on 20/01/26.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                // 1. If currently OPEN, close it
                if appModel.immersiveSpaceState == .open {
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    appModel.immersiveSpaceState = .closed
                }
                // 2. If currently CLOSED, open it
                else if appModel.immersiveSpaceState == .closed {
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: "PhysicsSpace") {
                    case .opened:
                        appModel.immersiveSpaceState = .open
                    case .userCancelled, .error:
                        appModel.immersiveSpaceState = .closed
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }
                }
            }
        } label: {
            // Update the label based on the state
            Text(appModel.immersiveSpaceState == .open ? "Stop Physics" : "Start Physics")
        }
        // Disable the button while the OS is transitioning states
        .disabled(appModel.immersiveSpaceState == .inTransition)
    }
}
