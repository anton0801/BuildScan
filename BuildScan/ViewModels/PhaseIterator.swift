import Foundation
import Combine
import AppsFlyerLib

struct Phase {
    let label: String
    let execute: () async throws -> PhaseResult
}

enum PhaseResult {
    case advance
    case finish(ScanOutcome)
    case skip
}

struct PhaseIterator: AsyncIteratorProtocol {
    typealias Element = PhaseResult
    
    private var phases: [Phase]
    private var cursor: Int = 0
    
    init(phases: [Phase]) {
        self.phases = phases
    }
    
    mutating func next() async throws -> PhaseResult? {
        guard cursor < phases.count else {
            return nil
        }
        let phase = phases[cursor]
        cursor += 1
        
        let result = try await phase.execute()
        return result
    }
}

struct PhaseSequence: AsyncSequence {
    typealias Element = PhaseResult
    typealias AsyncIterator = PhaseIterator
    
    private let phases: [Phase]
    
    init(phases: [Phase]) {
        self.phases = phases
    }
    
    func makeAsyncIterator() -> PhaseIterator {
        PhaseIterator(phases: phases)
    }
}

@MainActor
final class ScanPipeline {
    
    let state: ApertureState
    
    private let outcomeSubject = PassthroughSubject<ScanOutcome, Never>()
    var outcomePublisher: AnyPublisher<ScanOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let vault: HybridVault
    private let inspectorFactory: () -> VoltageInspector
    private let attributionFactory: () -> AttributionFetch
    private let locatorFactory: () -> CaptureLocator
    private let consenterFactory: () -> ConsentRequester
    
    init(
        state: ApertureState = ApertureState(),
        vault: HybridVault = HybridAESVault(),
        inspectorFactory: @escaping () -> VoltageInspector = { SupabaseVoltageInspector() },
        attributionFactory: @escaping () -> AttributionFetch = { AppsFlyerAttributionFetch() },
        locatorFactory: @escaping () -> CaptureLocator = { MainCaptureLocator() },
        consenterFactory: @escaping () -> ConsentRequester = { NotificationConsentRequester() }
    ) {
        self.state = state
        self.vault = vault
        self.inspectorFactory = inspectorFactory
        self.attributionFactory = attributionFactory
        self.locatorFactory = locatorFactory
        self.consenterFactory = consenterFactory
    }
    
    func warmUp() {
        let frame = vault.unwrap()
        state.hydrate(from: frame)
    }
    
    func ingestFrames(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.setFrames(mapped)
        vault.stashFrames(mapped)
    }
    
    func ingestLenses(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.setLenses(mapped)
        vault.stashLenses(mapped)
    }
    
    func shutter() async {
        guard !sequenceCompleted else { return }
        
        let phases = buildPhases()
        let sequence = PhaseSequence(phases: phases)
        
        do {
            for try await result in sequence {
                switch result {
                case .advance:
                    continue
                case .skip:
                    continue
                case .finish(let outcome):
                    sequenceCompleted = true
                    outcomeSubject.send(outcome)
                    return
                }
            }
        } catch let err as BuildScanError {
            if let recovery = err.recoverySuggestion {
            }
            sequenceCompleted = true
            outcomeSubject.send(.fallbackGallery)
        } catch {
            sequenceCompleted = true
            outcomeSubject.send(.fallbackGallery)
        }
    }
    
    func acceptConsent() async {
        let consenter = consenterFactory()
        
        let priorSnapped = state.consentSnapped
        let priorBlinkered = state.consentBlinkered
        
        let granted = await consenter.request()
        
        let now = Date()
        
        if granted {
            state.recordConsent(snapped: true, blinkered: false, at: now)
            consenter.arm()
        } else {
            state.recordConsent(snapped: false, blinkered: true, at: now)
        }
        
        _ = priorSnapped
        _ = priorBlinkered
        
        vault.stashConsent(snapped: state.consentSnapped, blinkered: state.consentBlinkered, at: now)
        outcomeSubject.send(.revealCapture)
    }
    
    func deferConsent() {
        let now = Date()
        state.recordConsent(snapped: state.consentSnapped, blinkered: state.consentBlinkered, at: now)
        vault.stashConsent(snapped: state.consentSnapped, blinkered: state.consentBlinkered, at: now)
        outcomeSubject.send(.revealCapture)
    }
    
    func reportDeadline() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
    
    private func buildPhases() -> [Phase] {
        return [
            buildPushShortCircuitPhase(),
            buildVoltageInspectionPhase(),
            buildOrganicRefetchPhase(),
            buildCaptureLocatePhase()
        ]
    }
    
    private func buildPushShortCircuitPhase() -> Phase {
        Phase(label: "pushShortCircuit") { [weak self] in
            guard let self = self else { return .skip }
            
            return await MainActor.run {
                guard let tempURL = UserDefaults.standard.string(forKey: LensKey.pushURL),
                      !tempURL.isEmpty else {
                    return .skip
                }
                
                let needsConsent = self.state.consentRipe
                
                self.state.setCapture(url: tempURL, mode: "Active")
                self.vault.stashCapture(url: tempURL, mode: "Active")
                self.vault.markDeveloped()
                UserDefaults.standard.removeObject(forKey: LensKey.pushURL)
                
                let outcome: ScanOutcome = needsConsent ? .requestPermission : .revealCapture
                return .finish(outcome)
            }
        }
    }
    
    private func buildVoltageInspectionPhase() -> Phase {
        Phase(label: "voltageInspection") { [weak self] in
            guard let self = self else { return .skip }
            
            let ready = await MainActor.run { self.state.framesPopulated }
            guard ready else {
                return .skip
            }
            
            let inspector = self.inspectorFactory()
            let future = inspector.inspect()
            
            do {
                let valid = try await future.tryAwait()
                if valid {
                    return .advance
                } else {
                    throw BuildScanError(
                        .lensInspectionDimmed,
                        detail: "verdict false",
                        recovery: "Check validation row"
                    )
                }
            } catch let err as BuildScanError {
                throw err
            } catch {
                throw BuildScanError(
                    .lensInspectionDimmed,
                    detail: "\(error)",
                    recovery: "Network or backend issue"
                )
            }
        }
    }
    
    private func buildOrganicRefetchPhase() -> Phase {
        Phase(label: "organicRefetch") { [weak self] in
            guard let self = self else { return .skip }
            
            let canRefetch = await MainActor.run {
                self.state.organicSource && self.state.virginRoll && !self.state.organicCheckpoint
            }
            
            guard canRefetch else {
                return .advance
            }
            
            await MainActor.run { self.state.setOrganicCheckpoint() }
            
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            let developed = await MainActor.run { self.state.developed }
            guard !developed else {
                return .advance
            }
            
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let fetcher = self.attributionFactory()
            
            do {
                var fetched = try await fetcher.fetch(deviceID: deviceID)
                
                let lenses = await MainActor.run { self.state.lenses }
                for (k, v) in lenses {
                    if fetched[k] == nil {
                        fetched[k] = v
                    }
                }
                
                let mapped = fetched.mapValues { "\($0)" }
                await MainActor.run { self.state.setFrames(mapped) }
                self.vault.stashFrames(mapped)
            } catch {
            }
            
            return .advance
        }
    }
    
    private func buildCaptureLocatePhase() -> Phase {
        Phase(label: "captureLocate") { [weak self] in
            guard let self = self else { return .skip }
            
            let ready = await MainActor.run { self.state.framesPopulated }
            guard ready else {
                return .skip
            }
            
            let frames = await MainActor.run { self.state.frames }
            let seed = frames.mapValues { $0 as Any }
            
            let locator = self.locatorFactory()
            let url = try await locator.locate(seed: seed)
            
            return await MainActor.run {
                let needsConsent = self.state.consentRipe
                
                self.state.setCapture(url: url, mode: "Active")
                self.vault.stashCapture(url: url, mode: "Active")
                self.vault.markDeveloped()
                UserDefaults.standard.removeObject(forKey: LensKey.pushURL)
                
                let outcome: ScanOutcome = needsConsent ? .requestPermission : .revealCapture
                return .finish(outcome)
            }
        }
    }
}
