import Foundation
import CryptoKit

protocol HybridVault {
    func stashFrames(_ data: [String: String])
    func stashLenses(_ data: [String: String])
    func stashCapture(url: String, mode: String)
    func stashConsent(snapped: Bool, blinkered: Bool, at: Date?)
    func markDeveloped()
    func unwrap() -> ApertureFrame
}

final class HybridAESVault: HybridVault {
    
    private let suiteVault: UserDefaults
    private let homeVault: UserDefaults
    private let symmetricKey: SymmetricKey
    
    init() {
        self.suiteVault = UserDefaults(suiteName: LensConstants.suiteLens)!
        self.homeVault = UserDefaults.standard
        
        self.symmetricKey = HybridAESVault.deriveKey()
    }
    
    private static func deriveKey() -> SymmetricKey {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.buildscan.app"
        let seed = "\(bundleID).\(LensConstants.encryptionTagKey)"
        let hash = SHA256.hash(data: Data(seed.utf8))
        return SymmetricKey(data: Data(hash))
    }
    
    func stashFrames(_ data: [String: String]) {
        guard let plaintext = encodeJSON(data) else { return }
        let (sealed, iv) = encrypt(plaintext)
        if let sealed = sealed {
            suiteVault.set(sealed, forKey: LensKey.frames)
            suiteVault.set(iv, forKey: LensKey.framesIV)
        }
    }
    
    func stashLenses(_ data: [String: String]) {
        guard let plaintext = encodeJSON(data) else { return }
        let (sealed, iv) = encrypt(plaintext)
        if let sealed = sealed {
            suiteVault.set(sealed, forKey: LensKey.lenses)
            suiteVault.set(iv, forKey: LensKey.lensesIV)
        }
    }
    
    func stashCapture(url: String, mode: String) {
        suiteVault.set(url, forKey: LensKey.captureURL)
        homeVault.set(url, forKey: LensKey.captureURL)
        suiteVault.set(mode, forKey: LensKey.captureMode)
    }
    
    func stashConsent(snapped: Bool, blinkered: Bool, at: Date?) {
        suiteVault.set(snapped, forKey: LensKey.consentSnapped)
        suiteVault.set(blinkered, forKey: LensKey.consentBlinkered)
        if let when = at {
            let ms = when.timeIntervalSince1970 * 1000
            suiteVault.set(ms, forKey: LensKey.consentClickAt)
        }
    }
    
    func markDeveloped() {
        suiteVault.set(true, forKey: LensKey.developed)
        homeVault.set(true, forKey: LensKey.developed)
    }
    
    func unwrap() -> ApertureFrame {
        let framesSealed = suiteVault.data(forKey: LensKey.frames)
        let framesIV = suiteVault.data(forKey: LensKey.framesIV)
        let frames: [String: String] = {
            guard let sealed = framesSealed, let iv = framesIV,
                  let plaintext = decrypt(sealed: sealed, iv: iv) else { return [:] }
            return decodeJSON(plaintext) ?? [:]
        }()
        
        let lensesSealed = suiteVault.data(forKey: LensKey.lenses)
        let lensesIV = suiteVault.data(forKey: LensKey.lensesIV)
        let lenses: [String: String] = {
            guard let sealed = lensesSealed, let iv = lensesIV,
                  let plaintext = decrypt(sealed: sealed, iv: iv) else { return [:] }
            return decodeJSON(plaintext) ?? [:]
        }()
        
        let url = suiteVault.string(forKey: LensKey.captureURL)
        let mode = suiteVault.string(forKey: LensKey.captureMode)
        let developed = suiteVault.bool(forKey: LensKey.developed)
        
        let snapped = suiteVault.bool(forKey: LensKey.consentSnapped)
        let blinkered = suiteVault.bool(forKey: LensKey.consentBlinkered)
        let atMs = suiteVault.double(forKey: LensKey.consentClickAt)
        let at = atMs > 0 ? Date(timeIntervalSince1970: atMs / 1000) : nil
        
        return ApertureFrame(
            frames: frames,
            lenses: lenses,
            captureURL: url,
            captureMode: mode,
            virginRoll: !developed,
            consentSnapped: snapped,
            consentBlinkered: blinkered,
            consentClickAt: at
        )
    }
    
    private func encrypt(_ plaintext: String) -> (Data?, Data?) {
        guard let data = plaintext.data(using: .utf8) else { return (nil, nil) }
        do {
            let nonce = AES.GCM.Nonce()
            let sealed = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
            guard let combined = sealed.combined else { return (nil, nil) }
            
            // Применяем character substitution к base64 representation
            let b64 = combined.base64EncodedString()
            let veiled = veil(b64)
            let veiledData = veiled.data(using: .utf8)
            
            return (veiledData, Data(nonce))
        } catch {
            return (nil, nil)
        }
    }
    
    private func decrypt(sealed: Data, iv: Data) -> String? {
        guard let veiledText = String(data: sealed, encoding: .utf8) else { return nil }
        let b64 = unveil(veiledText)
        guard let combinedData = Data(base64Encoded: b64) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: plaintext, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func encodeJSON(_ dict: [String: String]) -> String? {
        let any = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: any),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
    
    private func decodeJSON(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return any.mapValues { "\($0)" }
    }
    
    private func veil(_ input: String) -> String {
        // '/' → '.', '+' → ','
        input
            .replacingOccurrences(of: "/", with: ".")
            .replacingOccurrences(of: "+", with: ",")
    }
    
    private func unveil(_ input: String) -> String {
        input
            .replacingOccurrences(of: ".", with: "/")
            .replacingOccurrences(of: ",", with: "+")
    }
}
