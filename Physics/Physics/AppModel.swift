//
//  AppModel.swift
//  Physics
//
//  Created by Luca Langella 1 on 20/01/26.
//

import SwiftUI
import Observation
import RealityKit

enum ImmersiveSpaceState {
    case closed
    case inTransition
    case open
}

enum PhysicsModeOption: String, CaseIterable, Identifiable {
    case dynamic = "Dynamic"
    case staticMode = "Static"
    case kinematic = "Kinematic"
    
    var id: String { self.rawValue }
    
    var rkMode: PhysicsBodyMode {
        switch self {
        case .dynamic: return .dynamic
        case .staticMode: return .static
        case .kinematic: return .kinematic
        }
    }
}

@Observable
class AppModel {
    // --- System States ---
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var resetSignal = false
    // REMOVED: var impulseSignal = false (No longer needed)
    
    // --- Live Data ---
    var currentSpeed: Float = 0.0
    
    // --- Gesture Debugging ---
    var isDragging: Bool = false
    var throwStrength: Float = 8.0  // Editable multiplier
    var lastThrowVector: String = "0.0, 0.0, 0.0" // Debug info
    
    // --- Physics Properties ---
    var selectedMode: PhysicsModeOption = .dynamic
    var mass: Float = 1.0
    
    var staticFriction: Float = 0.5
    var dynamicFriction: Float = 0.5
    var restitution: Float = 0.6
    
    var linearDamping: Float = 0.0
    
    func triggerReset() { resetSignal.toggle() }
}
