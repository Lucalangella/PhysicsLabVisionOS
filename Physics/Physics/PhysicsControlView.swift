import SwiftUI

struct PhysicsControlView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        NavigationStack {
            List {
                // --- Section 1: Telemetry ---
                Section("Telemetry") {
                    HStack {
                        Label("Current Speed", systemImage: "speedometer")
                        Spacer()
                        Text("\(appModel.currentSpeed, specifier: "%.2f") m/s")
                            .font(.monospacedDigit(.body)())
                            .foregroundStyle(.secondary)
                    }
                }

                // --- NEW Section: Gesture Debug ---
                Section("Gesture Debug") {
                    // 1. Respawn Button
                    Button("Respawn Box") { appModel.triggerReset() }
                    
                    // 2. Status Indicator
                    HStack {
                        Text("Interaction Status")
                        Spacer()
                        Text(appModel.isDragging ? "GRABBING" : "IDLE")
                            .font(.caption.bold())
                            .padding(6)
                            .background(appModel.isDragging ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(appModel.isDragging ? .black : .primary)
                            .cornerRadius(8)
                    }
                    
                    // 3. Throw Strength Controller
                    VStack {
                        HStack {
                            Text("Throw Strength Multiplier")
                            Spacer()
                            Text(String(format: "x%.1f", appModel.throwStrength))
                                .foregroundStyle(.blue)
                        }
                        // Range from 1x to 20x force
                        Slider(value: Bindable(appModel).throwStrength, in: 1.0...20.0)
                    }
                    
                    // 4. Last Throw Vector
                    VStack(alignment: .leading) {
                        Text("Last Throw Vector (X, Y, Z)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(appModel.lastThrowVector)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                // --- Section 3: Behavior ---
                Section("Body Behavior") {
                    Picker("Mode", selection: Bindable(appModel).selectedMode) {
                        ForEach(PhysicsModeOption.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack {
                        HStack { Text("Mass"); Spacer(); Text("\(appModel.mass, specifier: "%.1f") kg") }
                        Slider(value: Bindable(appModel).mass, in: 0.1...50.0)
                    }
                }
                
                // --- Section 4: Material ---
                Section("Material (Surface)") {
                    VStack {
                        HStack { Text("Bounciness"); Spacer(); Text(String(format: "%.2f", appModel.restitution)) }
                        Slider(value: Bindable(appModel).restitution, in: 0.0...1.0)
                    }
                    
                    VStack {
                        HStack { Text("Sliding Friction"); Spacer(); Text(String(format: "%.2f", appModel.dynamicFriction)) }
                        Slider(value: Bindable(appModel).dynamicFriction, in: 0.0...1.0)
                    }
                    
                    VStack {
                        HStack { Text("Static Friction"); Spacer(); Text(String(format: "%.2f", appModel.staticFriction)) }
                        Slider(value: Bindable(appModel).staticFriction, in: 0.0...1.0)
                    }
                }
                
                // --- Section 5: Damping ---
                Section("Damping (Resistance)") {
                    VStack {
                        HStack { Text("Air Resistance"); Spacer(); Text(String(format: "%.2f", appModel.linearDamping)) }
                        Slider(value: Bindable(appModel).linearDamping, in: 0.0...5.0)
                    }
                }
            }
            .navigationTitle("Physics Lab")
        }
        .frame(width: 400, height: 1100)
    }
}
