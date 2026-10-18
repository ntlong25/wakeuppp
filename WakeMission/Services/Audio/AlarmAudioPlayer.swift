import Foundation
import AVFoundation

final class AlarmAudioPlayer: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    static let shared = AlarmAudioPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    private var safetyTimer: Timer?
    private let maxRingingDurationSeconds: TimeInterval = 600 // 10 minutes safety cutoff
    
    private override init() {
        super.init()
    }
    
    func playLooping(soundName: String = "Radar") {
        stop()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .alarm, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
        
        // Locate audio file in bundle, or generate synthetic alarm beep tone
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") ??
                          Bundle.main.url(forResource: soundName, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Failed to play audio file: \(error)")
            }
        } else {
            print("Bundled audio '\(soundName)' not found. Using system alert fallback.")
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        
        // Start 10-minute emergency safety cutoff timer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.safetyTimer?.invalidate()
            self.safetyTimer = Timer.scheduledTimer(withTimeInterval: self.maxRingingDurationSeconds, repeats: false) { [weak self] _ in
                print("Emergency 10-minute safety cutoff triggered.")
                self?.stop()
            }
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        safetyTimer?.invalidate()
        safetyTimer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate AVAudioSession: \(error)")
        }
    }
}
