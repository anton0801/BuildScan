import Foundation
import Combine

final class BufferColleague {
    
    var relayConversion: (([AnyHashable: Any]) -> Void)?
    var relayDeepLink: (([AnyHashable: Any]) -> Void)?
    
    private var conversionBuffer: [AnyHashable: Any] = [:]
    private var deepLinkBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptConversion(_ data: [AnyHashable: Any]) {
        conversionBuffer = data
        scheduleFuse()
        if !deepLinkBuffer.isEmpty { performFuse() }
    }
    
    func acceptDeepLink(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: LensKey.developed) else { return }
        deepLinkBuffer = data
        relayDeepLink?(data)
        fuseTimer?.invalidate()
        if !conversionBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = conversionBuffer
        for (k, v) in deepLinkBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        relayConversion?(combined)
    }
}
