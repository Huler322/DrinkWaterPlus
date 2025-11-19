import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private var manager = CMMotionManager()
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    
    init() {
        manager.deviceMotionUpdateInterval = 0.05
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            if let motion = motion {
                self.roll = motion.attitude.roll
                self.pitch = motion.attitude.pitch
            }
        }
    }
}
