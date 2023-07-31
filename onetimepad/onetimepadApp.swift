//
//  onetimepadApp.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import Combine
import Foundation
import FirebaseMessaging


struct User: Equatable {
    var uid: String
}

class UserManager: ObservableObject {
    @Published var currentUser: User?
    static let shared = UserManager()
    private init() {}
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var userManager: UserManager!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in
//              Messaging.messaging().token { token, error in
//                if let error = error {
//                  print("Error fetching FCM registration token: \(error)")
//                } else if let token = token {
//                  print("FCM registration token: \(token)")
//                  UserDefaults.standard.setValue(token, forKey: "token")
//                }
//              }
          }
        )

        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
//            self.fcmRegTokenMessage.text  = "Remote FCM registration token: \(token)"
          }
        }
        
        Auth.auth().signInAnonymously { authResult, error in
            guard let user = authResult?.user else { return }
            UserManager.shared.currentUser = User(uid: user.uid)
        }
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      UserDefaults.standard.setValue(dataDict["token"], forKey: "token")
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct onetimepadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            LoadingView()
        }
    }
}

struct LoadingView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State var loading = true
    
    var body: some View {
        if loading {
            Loading()
            .onChange(of: userManager.currentUser) { new in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                    withAnimation { loading = false }
                }
            }
        } else {
            LazyView(MainView())
        }
    }
}

struct Loading: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(colorScheme == .dark ? "darkIcon" : "lightIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
            }
            Spacer()
        }
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
