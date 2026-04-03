/// Smooth vertical oscillation used to animate creature bobbing.
enum BobAnimation {

    /// Returns a value in `[-amplitude, +amplitude]` using piecewise cubic ease-in-out.
    ///
    /// - Parameters:
    ///   - time: Current time in seconds (e.g., `CACurrentMediaTime()`).
    ///   - period: Full oscillation period in seconds.
    ///   - amplitude: Peak displacement in points.
    static func value(time: Double, period: Double, amplitude: Double) -> Double {
        guard amplitude > 0, period > 0 else { return 0 }

        // Phase in [0, 1)
        let phase = (time.truncatingRemainder(dividingBy: period)) / period

        // Cubic ease-in-out mapped to [-1, 1]
        let t: Double
        if phase < 0.5 {
            // Ease in: 0→0.5 maps to 0→1
            let p = phase * 2            // 0…1
            t = 2 * p * p * (3 - 2 * p)  // smoothstep
        } else {
            // Ease out: 0.5→1 maps to 1→0
            let p = (phase - 0.5) * 2    // 0…1
            t = 1 - 2 * p * p * (3 - 2 * p)
        }

        // Map [0, 1] → [-amplitude, +amplitude]
        return (t * 2 - 1) * amplitude
    }
}
