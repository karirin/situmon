//
//  UserViewModel.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/20.
//

import SwiftUI
import Firebase

class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var currentUserId: String?
    @Published var rooms: [Room] = []
    @Published var searchedUsers: [User] = [] // ユーザー検索結果を格納するための配列

    private var ref: DatabaseReference!

    init() {
        ref = Database.database().reference(withPath: "users")
        authenticateUser()
        self.users = users
    }

    func authenticateUser() {
        Auth.auth().signInAnonymously { (authResult, error) in
            guard let user = authResult?.user else {
                print("Failed to login or retrieve user: \(error?.localizedDescription ?? "")")
                return
            }
            self.currentUserId = user.uid
            self.fetchData { success in
                if success {
                    print("データの読み込みが成功しました")
                } else {
                    print("データの読み込みに失敗しました")
                }
            }
        }
    }
    
    func updateStatus(for userID: String, to newStatus: UserStatus) {
        ref.child(userID).updateChildValues(["status": newStatus.rawValue])
    }

    func fetchData(completion: @escaping (Bool) -> Void) {
        ref.observe(.value, with: { [weak self] snapshot in
            var newUsers: [User] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: Any],
                   let name = value["name"] as? String,
                   let icon = value["icon"] as? String,
                   let status = value["status"] as? String,
                   let userStatus = UserStatus(rawValue: status) {
                    
                    let rooms = value["rooms"] as? [String: Bool] ?? [:]
                    print("fetchData")
                    print(rooms)
                    
                    let user = User(id: childSnapshot.key, name: name, icon: icon, status: userStatus, rooms: rooms)
                    newUsers.append(user)
                }
            }
            self?.users = newUsers
            completion(true) // 読み込みが成功したらtrueを渡してコンプリーションハンドラを呼び出す
        }) { (error) in
            print("Failed to fetch data:", error.localizedDescription)
            completion(false) // エラーが発生したらfalseを渡してコンプリーションハンドラを呼び出す
        }
    }

    
        // ユーザーIDで検索する機能
//        func searchUserByName(_ name: String) {
//            if let currentUser = users.first(where: { $0.id == currentUserId }),
//               let userRooms = currentUser.rooms?.keys {
//
//                if let user = users.first(where: {
//                    $0.name == name &&
//                    !Set($0.rooms?.keys.map { $0 } ?? []).isDisjoint(with: Set(userRooms))
//                }) {
//                    print(user)
//                    searchedUsers = [user]
//                } else {
//                    searchedUsers = []
//                }
//            }
//        }
    
    func searchUserByName(_ name: String) {
        print(users)
        searchedUsers = users.filter { $0.name == name }
    }


    func createRoom(withName name: String) {
        // 部屋をroomsに追加する
        let newRoom = Room(id: UUID(), name: name, userIDs: [])
        self.rooms.append(newRoom)

        // 現在のユーザーのroom情報を更新する
        if let userId = self.currentUserId {
            let userRef = ref.child(userId)
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var userData = currentData.value as? [String: Any] ?? [:]
                var userRooms = userData["rooms"] as? [String: Bool] ?? [:]
                userRooms[name] = true
                userData["rooms"] = userRooms
                currentData.value = userData
                return TransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("Error updating user rooms: \(error.localizedDescription)")
                } else {
                    print("User rooms updated successfully!")
                }
            }
        }
    }

    // 指定の部屋にユーザーを追加する機能
    func addUserToRoom(_ user: User, to roomName: String) {
        // 既存のロジックの修正
        if let index = rooms.firstIndex(where: { $0.name == roomName }) {
            if !rooms[index].userIDs.contains(user.id) { // 重複を防ぐ
                rooms[index].userIDs.append(user.id)
            }
        } else {
            // もし部屋が存在しなければ新しく作成
            let newRoom = Room(id: UUID(), name: roomName, userIDs: [user.id])
            rooms.append(newRoom)
        }

        // ユーザーのroom情報を更新するロジック
        let userRoomPath = ref.child(user.id).child("rooms").child(roomName)
        userRoomPath.setValue(true)
        
        // 全てのユーザーのデータを再フェッチ
        fetchData { success in
            if success {
                print("データの読み込みが成功しました")
            } else {
                print("データの読み込みに失敗しました")
            }
        }

    }

}

