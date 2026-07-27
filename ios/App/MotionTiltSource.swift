/// MotionTiltSource — owns the CoreMotion feed behind the EXPRESSION tilt
/// routing. Armed only while both requested (routing on) and the application
/// is active, so backgrounding always releases the sensor. Folds the gravity
/// vector to the same "uprightness" 0 (flat on a table) → 1 (screen vertical)
/// the web build derives from DeviceOrientation, in any rotation.
import CoreMotion

final class MotionTiltSource {
    private let motion = CMMotionManager()
    private let onTilt: (Float) -> Void
    private var smoothed = 0.0
    private var requested = false
    private var applicationActive = true

    init(onTilt: @escaping (Float) -> Void) {
        self.onTilt = onTilt
    }

    /// Routing on/off. Turning off stops the sensor and re-centers the axis.
    func setRequested(_ value: Bool) {
        requested = value
        sync()
    }

    /// Scene-phase input: the sensor never runs in the background.
    func setApplicationActive(_ value: Bool) {
        applicationActive = value
        sync()
    }

    private func sync() {
        let wanted = requested && applicationActive
        if wanted && motion.isDeviceMotionAvailable && !motion.isDeviceMotionActive {
            motion.deviceMotionUpdateInterval = 1.0 / 30
            motion.startDeviceMotionUpdates(to: .main) { [weak self] dm, _ in
                guard let self, let gravity = dm?.gravity else { return }
                // |gravity.z| is the vertical component of the screen normal:
                // 1 face-up/face-down, 0 screen-vertical.
                let upright = 1 - min(1, abs(gravity.z))
                self.smoothed += (upright - self.smoothed) * 0.25
                self.onTilt(Float(self.smoothed))
            }
        } else if !wanted && motion.isDeviceMotionActive {
            motion.stopDeviceMotionUpdates()
            smoothed = 0
            onTilt(0)
        }
    }
}
