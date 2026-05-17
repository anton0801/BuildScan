import Foundation
import Combine
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

final class MainCaptureLocator: CaptureLocator {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BuildScanError(.wireUnplugged, detail: "non-HTTP response")
        }
        
        if http.statusCode == 404 {
            throw BuildScanError(.captureRefused, detail: "404 Not Found")
        }
        
        if http.statusCode == 429 {
            throw BuildScanError(.shutterStuck, detail: "429 throttled")
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw BuildScanError(.wireUnplugged, detail: "HTTP \(http.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BuildScanError(.dataGrainy, detail: "JSON parse failed")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw BuildScanError(.dataGrainy, detail: "missing 'ok' field")
        }
        
        if !ok {
            throw BuildScanError(.captureRefused, detail: "server ok:false")
        }
        
        guard let url = json["url"] as? String else {
            throw BuildScanError(.dataGrainy, detail: "missing 'url' field")
        }
        
        return url
    }
    
    private let waitPlan: [Double] = [68.0, 136.0, 272.0]
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    func locate(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: LensConstants.backendStudio) else {
            throw BuildScanError(.dataGrainy, detail: "endpoint URL build failed")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(LensConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: LensKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastError: Error?
        
        for (idx, wait) in waitPlan.enumerated() {
            do {
                return try await singleShot(request)
            } catch let err as BuildScanError where err.kind == .captureRefused {
                throw err
            } catch let err as BuildScanError where err.kind == .shutterStuck {
                let waitTime = wait * Double(idx + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if idx < waitPlan.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
        }
        
        if let lastError = lastError {
            throw lastError
        }
        throw BuildScanError(.wireUnplugged, detail: "all retries exhausted")
    }
    
}
