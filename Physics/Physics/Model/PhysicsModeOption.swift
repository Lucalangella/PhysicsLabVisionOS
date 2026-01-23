import Foundation
import RealityKit

enum PhysicsModeOption: String, CaseIterable, Identifiable {
    case dynamic = "Dynamic"
    
    var id: String { self.rawValue }
    
    var rkMode: PhysicsBodyMode {
        switch self {
        case .dynamic: return .dynamic
        }
    }
}
