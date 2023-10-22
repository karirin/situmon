//
//  situmonApp.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/20.
//

import SwiftUI
import Firebase

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    return true
}

@main
struct situmonApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            UserListView()
        }
    }
}
