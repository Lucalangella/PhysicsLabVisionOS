//
//  ToggleImmersiveSpaceButton.swift
//  Physics
//
//  Created by Luca Langella 1 on 20/01/26.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Environment(AppViewModel.self) var appViewModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                // 1. If currently OPEN, close it
                if appViewModel.immersiveSpaceState == .open {
                    appViewModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    appViewModel.immersiveSpaceState = .closed
                }
                // 2. If currently CLOSED, open it
                else if appViewModel.immersiveSpaceState == .closed {
                    appViewModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: "PhysicsSpace") {
                    case .opened:
                        appViewModel.immersiveSpaceState = .open
                    case .userCancelled, .error:
                        appViewModel.immersiveSpaceState = .closed
                    @unknown default:
                        appViewModel.immersiveSpaceState = .closed
                    }
                }
            }
        } label: {
            // Update the label based on the state
            Text(appViewModel.immersiveSpaceState == .open ? "Stop Physics" : "Start Physics")
        }
        // Disable the button while the OS is transitioning states
        .disabled(appViewModel.immersiveSpaceState == .inTransition)
    }
}