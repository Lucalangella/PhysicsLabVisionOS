import SwiftUI
import RealityKit

// MARK: - Main Control View
struct PhysicsControlView: View {
    @Environment(AppViewModel.self) var vm

    var body: some View {
        // Create a bindable reference to the view model for UI controls
        @Bindable var bVM = vm
        
        HStack(alignment: .top, spacing: 30) {
            
            // --- Column 1: Object Properties (Internal Physics) ---
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Object Properties", icon: "cube.fill")
                
                // Shape Picker
                Picker("Shape", selection: $bVM.selectedShape) {
                    ForEach(ShapeOption.allCases) { shape in
                        Text(shape.rawValue).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Physics Sliders (Mass, Bounce, Friction)
                Group {
                    PhysicsSlider(label: "Mass", value: $bVM.mass, range: 0.1...50.0, unit: "kg")
                    PhysicsSlider(label: "Bounciness", value: $bVM.restitution, range: 0.0...1.0, unit: "")
                    PhysicsSlider(label: "Static Friction", value: $bVM.staticFriction, range: 0.0...1.0, unit: "")
                    PhysicsSlider(label: "Dynamic Friction", value: $bVM.dynamicFriction, range: 0.0...1.0, unit: "")
                }
            }
            .frame(maxWidth: .infinity)
            
            // Vertical Divider
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1)
            
            // --- Column 2: Environment (External Forces) ---
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Environment", icon: "globe.europe.africa.fill")
                
                // Telemetry Readout Box
                HStack {
                    VStack(alignment: .leading) {
                        Text("VELOCITY")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(.secondary)
                        Text("\(vm.currentSpeed, specifier: "%.2f") m/s")
                            .font(.title2).monospacedDigit()
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("STATUS")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(.secondary)
                        Text(vm.isDragging ? "HOLDING" : "IDLE")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(vm.isDragging ? Color.green : Color.gray.opacity(0.3))
                            .foregroundStyle(vm.isDragging ? .black : .primary)
                            .cornerRadius(4)
                    }
                }
                .padding()
                .background(.black.opacity(0.2))
                .cornerRadius(12)
                
                // --- NEW: Wall Settings (Appears only when Walls are ON) ---
                if vm.showWalls {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Wall Configuration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        PhysicsSlider(label: "Height", value: $bVM.wallHeight, range: 0.1...2.0, unit: "m")
                    }
//                    .padding()
//                    .background(.white.opacity(0.05))
//                    .cornerRadius(10)
                    .transition(.move(edge: .top).combined(with: .opacity)) // Smooth animation
                }

                // Gravity Slider
                PhysicsSlider(label: "Gravity Y", value: $bVM.gravity, range: -20.0...0.0, unit: "m/s²")
                
                // Aerodynamics Section
                VStack(alignment: .leading, spacing: 10) {
//                    Toggle("Advanced Aerodynamics", isOn: $bVM.useAdvancedDrag)
//                        .toggleStyle(.switch)
//                    
//                    if vm.useAdvancedDrag {
                        PhysicsSlider(label: "Air Resistance", value: $bVM.airDensity, range: 0.0...5.0, unit: "kg/m³")
                        
//                        // Read-only info for advanced drag
//                        HStack {
//                            Text("Cd: \(vm.dragCoefficient, specifier: "%.2f")")
//                            Spacer()
//                            Text("Area: \(vm.crossSectionalArea, specifier: "%.3f") m²")
//                        }
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
                        
//                    }
//                    else {
//                        PhysicsSlider(label: "Linear damping", value: $bVM.linearDamping, range: 0.0...5.0, unit: "")
//                    }
                }
//                .padding()
//                .background(.white.opacity(0.05))
//                .cornerRadius(10)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(), value: vm.showWalls) // Animate the layout change
            
            
            if vm.showRamp {
                // Vertical Divider
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1)
                RampSettingsPanel(vm: vm)
                    /*.offset(x: 340)*/ // Position it to the right of the main board
            }
            
        }
        .padding(40)
//        .glassBackgroundEffect()
        
        // --- Bottom Toolbar Ornament ---
        .ornament(attachmentAnchor: .scene(.bottom)) {
            DashboardToolbar(vm: vm)
        }
        
//        // --- Conditional Ramp Panel Overlay ---
//        .overlay(alignment: .trailing) {
//            if vm.showRamp {
//                RampSettingsPanel(vm: vm)
//                    .offset(x: 340) // Position it to the right of the main board
//            }
//        }
    }
}

// MARK: - Helper Components

/// A custom slider that adapts RealityKit's `Float` to SwiftUI's `Double` requirements.
struct PhysicsSlider: View {
    let label: String
    @Binding var value: Float
    var range: ClosedRange<Float>
    var unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value, specifier: "%.2f") \(unit)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(.blue)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.title3)
        .fontWeight(.semibold)
    }
}

struct DashboardToolbar: View {
    @Bindable var vm: AppViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { vm.triggerReset() }) {
                Label("Respawn", systemImage: "arrow.counterclockwise")
                    .padding(.vertical, 8)
            }
            
            Divider().frame(height: 20)
            
            Toggle(isOn: $vm.showWalls) {
                Label("Walls", systemImage: "square.split.bottomright.fill")
            }
            .toggleStyle(.button)
            
            Toggle(isOn: $vm.showRamp) {
                Label("Ramp", systemImage: "arrow.triangle.up.right")
            }
            .toggleStyle(.button)
            
            Toggle(isOn: $vm.showPath) {
                Label("Trace", systemImage: "scribble")
            }
            .toggleStyle(.button)
        }
        .padding()
        .glassBackgroundEffect()
    }
}

struct RampSettingsPanel: View {
    @Bindable var vm: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "Ramp Config", icon: "scalemass")
            
            PhysicsSlider(label: "Angle", value: $vm.rampAngle, range: 0.0...60.0, unit: "°")
            PhysicsSlider(label: "Length", value: $vm.rampLength, range: 0.5...5.0, unit: "m")
            PhysicsSlider(label: "Width", value: $vm.rampWidth, range: 0.5...5.0, unit: "m")
            PhysicsSlider(label: "Rotation", value: $vm.rampRotation, range: 0.0...360.0, unit: "°")
        }
//        .padding(20)
//        .frame(width: 300)
//        .glassBackgroundEffect()
    }
}

// MARK: - Preview
#Preview(windowStyle: .automatic) {
    PhysicsControlView()
        .environment(AppViewModel())
}
