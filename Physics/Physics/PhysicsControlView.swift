import SwiftUI

struct PhysicsControlView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        NavigationStack {
            List {
                Section("Telemetry") {
                    HStack {
                        Label("Current Speed", systemImage: "speedometer")
                        Spacer()
                        Text("\(appModel.currentSpeed, specifier: "%.2f") m/s")
                            .font(.monospacedDigit(.body)())
                            .foregroundStyle(.secondary)
                    }
                }
                
                

                Section("Environment") {
                    VStack {
                        HStack {
                            Text("Gravity (Y-Axis)")
                            Spacer()
                            Text(String(format: "%.1f m/s²", appModel.gravity))
                                .foregroundStyle(.blue)
                        }
                        Slider(value: Bindable(appModel).gravity, in: -20.0...0.0)
                    }
                }
                
                // Place this inside the List, perhaps after "Environment"
                Section("Inclined Plane (Ramp)") {
                    Toggle("Enable Ramp", isOn: Bindable(appModel).showRamp)
                    
                    if appModel.showRamp {
                        VStack {
                            HStack {
                                Text("Angle")
                                Spacer()
                                Text("\(appModel.rampAngle, specifier: "%.0f")°")
                                    .foregroundStyle(.blue)
                            }
                            // 0 to 60 degrees is usually enough for friction tests
                            Slider(value: Bindable(appModel).rampAngle, in: 0.0...60.0)
                        }
                        
                        VStack {
                            HStack {
                                Text("Length")
                                Spacer()
                                Text(String(format: "%.1f m", appModel.rampLength))
                                    .foregroundStyle(.blue)
                            }
                            Slider(value: Bindable(appModel).rampLength, in: 0.5...5.0)
                        }
                        
                        VStack {
                            HStack {
                                Text("Width")
                                Spacer()
                                Text(String(format: "%.1f m", appModel.rampWidth))
                                    .foregroundStyle(.blue)
                            }
                            Slider(value: Bindable(appModel).rampWidth, in: 0.5...5.0)
                        }
                        
                        VStack {
                            HStack {
                                Text("Rotation")
                                Spacer()
                                Text("\(appModel.rampRotation, specifier: "%.0f")°")
                                    .foregroundStyle(.blue)
                            }
                            Slider(value: Bindable(appModel).rampRotation, in: 0.0...360.0)
                        }
                    }
                }

                Section("Interaction") {
                    Button("Respawn Object") { appModel.triggerReset() }
                    
                    Toggle("Show Motion Path (Plot)", isOn: Bindable(appModel).showPath)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(appModel.isDragging ? "HOLDING" : "IDLE")
                            .font(.caption.bold())
                            .padding(6)
                            .background(appModel.isDragging ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(appModel.isDragging ? .black : .primary)
                            .cornerRadius(8)
                    }
                    
                    Text("Object will drop vertically on release.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Body Properties") {
                    // NEW: Shape Picker
                    Picker("Shape", selection: Bindable(appModel).selectedShape) {
                        ForEach(ShapeOption.allCases) { shape in
                            Text(shape.rawValue).tag(shape)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack {
                        HStack { Text("Mass"); Spacer(); Text("\(appModel.mass, specifier: "%.1f") kg") }
                        Slider(value: Bindable(appModel).mass, in: 0.1...50.0)
                    }
                    
                    VStack {
                        HStack { Text("Bounciness"); Spacer(); Text(String(format: "%.2f", appModel.restitution)) }
                        Slider(value: Bindable(appModel).restitution, in: 0.0...1.0)
                    }
                    
                    VStack {
                                        HStack {
                                            Text("Static Friction")
                                            Spacer()
                                            Text(String(format: "%.2f", appModel.staticFriction))
                                        }
                                        Slider(value: Bindable(appModel).staticFriction, in: 0.0...1.0)
                                    }
                                    
                         
                                    VStack {
                                        HStack {
                                            Text("Dynamic Friction")
                                            Spacer()
                                            Text(String(format: "%.2f", appModel.dynamicFriction))
                                        }
                                        Slider(value: Bindable(appModel).dynamicFriction, in: 0.0...1.0)
                                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Advanced Aerodynamics", isOn: Bindable(appModel).useAdvancedDrag)
                        
                        if appModel.useAdvancedDrag {
                            HStack {
                                Text("Air Density")
                                Spacer()
                                Text(String(format: "%.3f kg/m³", appModel.airDensity))
                            }
                            Slider(value: Bindable(appModel).airDensity, in: 0.0...5.0)
                            
                            // Info display
                            Grid(alignment: .leading, verticalSpacing: 5) {
                                GridRow {
                                    Text("Drag Coeff (Cd):")
                                    Text(String(format: "%.2f", appModel.dragCoefficient))
                                }
                                GridRow {
                                    Text("Area (A):")
                                    Text(String(format: "%.3f m²", appModel.crossSectionalArea))
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                        } else {
                            HStack { Text("Air Resistance (Linear)"); Spacer(); Text(String(format: "%.2f", appModel.linearDamping)) }
                            Slider(value: Bindable(appModel).linearDamping, in: 0.0...5.0)
                        }
                    }
                }
            }
            .navigationTitle("Physics Lab")
        }
    }
}

struct DraggableMenuWrapper: View {
    // Track the position of the menu
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero

    var body: some View {
        PhysicsControlView()
            .glassBackgroundEffect()
            // Apply the drag offset here
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update position while dragging
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        // Save the new position when let go
                        lastOffset = offset
                    }
            )
            // Push it back in Z-space slightly so it doesn't clip your nose
            .transform3DEffect(.init(translation: .init(x: 0, y: 0, z: -400)))
    }
}

#Preview("Full App Experience", immersionStyle: .mixed) {
    ZStack { // 1. Use ZStack to layer them on top of each other
        ImmersiveView()
        
        DraggableMenuWrapper()
        // 2. Set the Size FIRST
            .frame(width: 500, height: 1500)
        
        
        // 4. Move it in 3D Space
        // Note: Z = -500 puts it roughly arm's length away.
        // -2500 is extremely far away and might make it invisible.
            .transform3DEffect(.init(translation: .init(x: 1000, y: -1000, z: -2500)))
    }
    .environment(AppModel())
}
