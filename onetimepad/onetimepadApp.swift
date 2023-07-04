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


struct User: Equatable {
    var uid: String
}

class UserManager: ObservableObject {
    @Published var currentUser: User?
    static let shared = UserManager()
    private init() {}
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var userManager: UserManager!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously { authResult, error in
            guard let user = authResult?.user else { return }
            UserManager.shared.currentUser = User(uid: user.uid)
        }
        return true
    }
}

@main
struct onetimepadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
