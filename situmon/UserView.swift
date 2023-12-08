//
//  UserView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/12/03.
//

import SwiftUI
import Firebase

struct UserView: View {
    var user: User
    @ObservedObject var viewModel = UserViewModel()
    var room: Room
    @State private var currentUser: User?
    @State private var availableStatuses: [String] = []
    @State private var selectedStatus: String = ""
    @StateObject var statusColorManager = StatusColorManager.shared
    
    var body: some View {
        VStack{
            HStack {
                // ステータスに応じた色の丸表示
                Circle()
                    .fill(statusColorManager.color(forUserId: user.id))
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 5)
                    .onChange(of: statusColorManager.colorUpdated) { _ in
                        if let statusKey = room.statusKey(forLabel: selectedStatus) {
                            StatusColorManager.shared.updateColor(forUserId: user.id, withStatus: statusKey)
                            // ここでログ出力
                            print("Status Updated: \(selectedStatus), Color Updated for User ID: \(user.id)")
                        }
                    }
                
                // アイコン表示
                VStack{
                    Image(user.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    Text(user.name)
                }.padding(.trailing, 5)
                
                // ステータス表示
                if let currentUser = currentUser, currentUser.id == user.id {
                    UserStatusUpdateView(
                        selectedStatus: $selectedStatus,
                        statuses: availableStatuses,
                        updateAction: { newStatus in
                            if currentUser.id == user.id {
                                updateUserStatus(in: room.name, userId: user.id, newStatus: newStatus)
//                                StatusColorManager.shared.updateColor(forUserId: user.id, withStatus: newStatus)
                            }
                        }
                    )
                }else{
                    Text(StatusColorManager.shared.userStatus(forUserId: user.id))
                        .font(.system(size:18))
                        .padding(.leading, 10)
                }
                Spacer()
            }
            .onAppear{
                // ログイン中のユーザーのステータスを取得する
                fetchCurrentUserStatus(userId: user.id, in: room.name) { status in
                    if let status = status {
                        selectedStatus = status
                    }
                }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        // 認証成功時の処理
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
                    } else {
                        // 認証失敗時の処理
                    }
                }
                fetchAvailableStatuses(for: room.name) { statuses in
                    availableStatuses = statuses
                }
//                fetchRoomsData()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    func fetchCurrentUserStatus(userId: String, in roomName: String, completion: @escaping (String?) -> Void) {
        let userStatusRef = Database.database().reference(withPath: "rooms/\(roomName)/Userstatus/\(userId)")
        userStatusRef.observeSingleEvent(of: .value, with: { snapshot in
            let status = snapshot.value as? String
            completion(status)
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }
    
//    func fetchRoomsData() {
//        let roomsRef = Database.database().reference(withPath: "rooms")
//
//        roomsRef.observeSingleEvent(of: .value, with: { snapshot in
//            guard let roomsValue = snapshot.value as? [String: Any] else {
//                print("No rooms data found")
//                return
//            }
//            var Statuses: [String: String] = [:] // ユーザーIDをキーとするステータスの辞書
//            var userStatuses: [String: String] = [:]
//
//            for (_, roomData) in roomsValue {
//                if let roomInfo = roomData as? [String: Any],
//                   let userStatus = roomInfo["Userstatus"] as? [String: String],
//                   let statuses = roomInfo["statuses"] as? [String: String] {
//                    // 各ユーザーのステータスを特定
//                    for (userId, statusValue) in userStatus {
//                        for (statusKey, statusLabel) in statuses {
//                            if statusValue == statusLabel {
//                                Statuses[userId] = statusKey
//                            }
//                        }
//                    }
//                    
//                    for (userId, statusValue) in userStatus {
//                        userStatuses[userId] = statusValue
//                    }
//                }
//            }
//
//            // ここでStatusColorManagerのマッピングを更新する
//            StatusColorManager.shared.updateStatusColors(with: Statuses)
//            StatusColorManager.shared.updateuserStatus(with: userStatuses)
//        }) { error in
//            print(error.localizedDescription)
//        }
//    }
    
    func fetchAvailableStatuses(for roomName: String, completion: @escaping ([String]) -> Void) {
        let statusesRef = Database.database().reference(withPath: "rooms/\(roomName)/statuses")
        statusesRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let statusesDict = snapshot.value as? [String: String] else {
                print("Statuses not found")
                completion([])
                return
            }

            let statuses = Array(statusesDict.values)
            completion(statuses)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    func updateUserStatus(in roomName: String, userId: String, newStatus: String) {
        let userStatusRef = Database.database().reference(withPath: "rooms/\(roomName)/Userstatus/\(userId)")
        userStatusRef.setValue(newStatus) { error, _ in
            if let error = error {
                print("Error updating user status: \(error.localizedDescription)")
            } else {
                print("User status updated successfully")
            }
        }
    }
}
