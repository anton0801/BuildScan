import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var mediator: LaunchMediator!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        mediator = LaunchMediator(host: self)
        mediator.activate()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            mediator.handlePushPayload(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        mediator.kickoffTracking()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { [weak self] token, err in
            guard err == nil, let t = token else { return }
            self?.mediator.handleFCMToken(t)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        mediator.handlePushPayload(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        mediator.handlePushPayload(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        mediator.handlePushPayload(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        mediator.handleConversionData(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        mediator.handleConversionData([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        mediator.handleDeepLink(link.clickEvent)
    }
}

final class LaunchMediator {
    
    private let firebaseColleague: FirebaseColleague
    private let messagingColleague: MessagingColleague
    private let appsflyerColleague: AppsFlyerColleague
    private let bufferColleague: BufferColleague
    private let pushColleague: PushColleague
    
    private weak var host: AppDelegate?
    
    init(host: AppDelegate) {
        self.host = host
        self.firebaseColleague = FirebaseColleague()
        self.messagingColleague = MessagingColleague()
        self.appsflyerColleague = AppsFlyerColleague()
        self.bufferColleague = BufferColleague()
        self.pushColleague = PushColleague()
    }
    
    func activate() {
        firebaseColleague.boot()
        
        if let host = host {
            messagingColleague.attach(
                messagingDelegate: host,
                notificationDelegate: host
            )
            appsflyerColleague.attach(
                delegate: host,
                deeplinkDelegate: host
            )
        }
        
        bufferColleague.relayConversion = { [weak self] data in
            self?.broadcastConversionData(data)
        }
        bufferColleague.relayDeepLink = { [weak self] data in
            self?.broadcastDeepLink(data)
        }
        
        pushColleague.relayURL = { [weak self] url in
            self?.broadcastPushURL(url)
        }
    }
    
    func kickoffTracking() {
        appsflyerColleague.kickoff()
    }
    
    func handleConversionData(_ data: [AnyHashable: Any]) {
        bufferColleague.acceptConversion(data)
    }
    
    func handleDeepLink(_ data: [AnyHashable: Any]) {
        bufferColleague.acceptDeepLink(data)
    }
    
    func handlePushPayload(_ payload: [AnyHashable: Any]) {
        pushColleague.process(payload)
    }
    
    func handleFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: LensKey.fcm)
        UserDefaults.standard.set(token, forKey: LensKey.push)
        UserDefaults(suiteName: LensConstants.suiteLens)?.set(token, forKey: "shared_fcm")
    }
    
    // MARK: - Broadcasts (mediator → external system)
    
    private func broadcastConversionData(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastDeepLink(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
    
    private func broadcastPushURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: LensKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
}

final class MessagingColleague {
    func attach(messagingDelegate: MessagingDelegate, notificationDelegate: UNUserNotificationCenterDelegate) {
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
}

final class AppsFlyerColleague {
    func attach(delegate: AppsFlyerLibDelegate, deeplinkDelegate: DeepLinkDelegate) {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = LensConstants.trackerKey
        sdk.appleAppID = LensConstants.appCode
        sdk.delegate = delegate
        sdk.deepLinkDelegate = deeplinkDelegate
        sdk.isDebug = false
    }
    
    func kickoff() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

final class FirebaseColleague {
    func boot() {
        FirebaseApp.configure()
    }
}


final class NotificationConsentRequester: ConsentRequester {
    
    func request() async -> Bool {
        await Task.yield()
        
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func arm() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
