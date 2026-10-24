import Foundation
import AVFoundation

enum AlarmTone: String, CaseIterable, Identifiable, Sendable {
    case classic = "Classic"
    case digital = "Digital"
    case siren = "Siren"

    var id: String { rawValue }

    static func from(_ name: String) -> AlarmTone { AlarmTone(rawValue: name) ?? .classic }
}

/// Builds a loopable 16-bit mono WAV in memory so the app needs no bundled audio assets.
enum ToneSynth {
    static let sampleRate = 44_100

    static func wavData(for tone: AlarmTone) -> Data {
        var samples: [Int16] = []
        switch tone {
        case .classic:
            // 4 beeps of 880 Hz (0.15 s on / 0.1 s off), then 1 s silence.
            for _ in 0..<4 {
                samples += sine(freq: 880, seconds: 0.15)
                samples += silence(0.10)
            }
            samples += silence(1.0)
        case .digital:
            for _ in 0..<6 {
                samples += square(freq: 1200, seconds: 0.08)
                samples += silence(0.06)
            }
            samples += silence(0.8)
        case .siren:
            samples += sweep(from: 600, to: 1000, seconds: 0.8)
            samples += sweep(from: 1000, to: 600, seconds: 0.8)
        }
        return wav(from: samples)
    }

    private static func sine(freq: Double, seconds: Double) -> [Int16] {
        let n = Int(Double(sampleRate) * seconds)
        return (0..<n).map { i in
            let envelope = envelopeValue(i, n)
            return Int16(sin(2 * .pi * freq * Double(i) / Double(sampleRate)) * 0.9 * envelope * Double(Int16.max))
        }
    }

    private static func square(freq: Double, seconds: Double) -> [Int16] {
        let n = Int(Double(sampleRate) * seconds)
        return (0..<n).map { i in
            let s = sin(2 * .pi * freq * Double(i) / Double(sampleRate)) >= 0 ? 1.0 : -1.0
            return Int16(s * 0.6 * envelopeValue(i, n) * Double(Int16.max))
        }
    }

    private static func sweep(from f0: Double, to f1: Double, seconds: Double) -> [Int16] {
        let n = Int(Double(sampleRate) * seconds)
        var phase = 0.0
        return (0..<n).map { i in
            let f = f0 + (f1 - f0) * Double(i) / Double(n)
            phase += 2 * .pi * f / Double(sampleRate)
            return Int16(sin(phase) * 0.9 * Double(Int16.max))
        }
    }

    private static func silence(_ seconds: Double) -> [Int16] {
        [Int16](repeating: 0, count: Int(Double(sampleRate) * seconds))
    }

    /// Short fade in/out to avoid clicks.
    private static func envelopeValue(_ i: Int, _ n: Int) -> Double {
        let edge = max(1, min(200, n / 4))
        if i < edge { return Double(i) / Double(edge) }
        if i > n - edge { return Double(n - i) / Double(edge) }
        return 1
    }

    private static func wav(from samples: [Int16]) -> Data {
        var data = Data()
        let byteCount = samples.count * 2
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8)); u32(UInt32(36 + byteCount))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate * 2)); u16(2); u16(16)
        data.append(contentsOf: Array("data".utf8)); u32(UInt32(byteCount))
        for s in samples { u16(UInt16(bitPattern: s)) }
        return data
    }
}

@MainActor
final class AlarmAudioPlayer {
    static let shared = AlarmAudioPlayer()

    /// In-app audio stops by itself after this long (battery / runaway protection). Missions remain required.
    static let maxRingingDuration: TimeInterval = 10 * 60

    private var player: AVAudioPlayer?
    private var safetyTask: Task<Void, Never>?

    private init() {}

    var isPlaying: Bool { player?.isPlaying ?? false }

    func playLooping(tone: AlarmTone) {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            let p = try AVAudioPlayer(data: ToneSynth.wavData(for: tone))
            p.numberOfLoops = -1
            p.volume = 1.0
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            print("Alarm audio failed: \(error)")
        }

        safetyTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.maxRingingDuration))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    func stop() {
        safetyTask?.cancel()
        safetyTask = nil
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
