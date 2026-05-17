import Foundation
import Combine

final class ApertureState: ObservableObject {
    
    @Published private(set) var frames: [String: String] = [:]
    @Published private(set) var lenses: [String: String] = [:]
    @Published private(set) var captureURL: String?
    @Published private(set) var captureMode: String?
    @Published private(set) var virginRoll: Bool = true
    @Published private(set) var developed: Bool = false
    @Published private(set) var consentSnapped: Bool = false
    @Published private(set) var consentBlinkered: Bool = false
    @Published private(set) var consentClickAt: Date?
    @Published private(set) var organicCheckpoint: Bool = false
    
    var framesPopulated: Bool { !frames.isEmpty }
    var organicSource: Bool { frames["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentSnapped && !consentBlinkered else { return false }
        if let date = consentClickAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    func setFrames(_ data: [String: String]) {
        frames = data
    }
    
    func setLenses(_ data: [String: String]) {
        lenses = data
    }
    
    func setCapture(url: String, mode: String) {
        captureURL = url
        captureMode = mode
        virginRoll = false
        developed = true
    }
    
    func recordConsent(snapped: Bool, blinkered: Bool, at: Date?) {
        consentSnapped = snapped
        consentBlinkered = blinkered
        consentClickAt = at
    }
    
    func setOrganicCheckpoint() {
        organicCheckpoint = true
    }
    
    func hydrate(from frame: ApertureFrame) {
        frames = frame.frames
        lenses = frame.lenses
        captureURL = frame.captureURL
        captureMode = frame.captureMode
        virginRoll = frame.virginRoll
        consentSnapped = frame.consentSnapped
        consentBlinkered = frame.consentBlinkered
        consentClickAt = frame.consentClickAt
    }
}
