import Foundation
import Combine
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

protocol VoltageInspector {
    func inspect() -> Future<Bool, Error>
}

protocol AttributionFetch {
    func fetch(deviceID: String) async throws -> [String: Any]
}

protocol CaptureLocator {
    func locate(seed: [String: Any]) async throws -> String
}

protocol ConsentRequester {
    func request() async -> Bool
    func arm()
}

final class SupabaseVoltageInspector: VoltageInspector {
    
    func inspect() -> Future<Bool, Error> {
        return Future { [weak self] promise in
            promise(.success(true))
        }
    }
}

extension Future where Failure == Error {
    func tryAwait() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
            )
        }
    }
}


