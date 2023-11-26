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
    @StateObject var viewModel = UserViewModel()
    @ObservedObject var authManager: AuthManager
    @State private var selectedRoom: Room?
    
    init() {
        FirebaseApp.configure()
        authManager = AuthManager.shared
    }

    var body: some Scene {
        WindowGroup {
            if authManager.user == nil {
                RegisterView(viewModel: viewModel)
            } else {
                RoomListView()
            }
        }
    }
}
