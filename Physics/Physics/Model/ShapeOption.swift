import Foundation

enum ShapeOption: String, CaseIterable, Identifiable {
    case box = "Cube"
    case sphere = "Sphere"
    case cylinder = "Cylinder"
    
    var id: String { self.rawValue }
}
