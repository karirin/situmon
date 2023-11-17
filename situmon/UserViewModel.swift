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
    @Published var activeRooms: [Room] = []
    @Published var isUserNameTaken: Bool = false
    @Published var existingGroups: [String] = []
    
    var sortedActiveRooms: [Room] {
        activeRooms.sorted { $0.name < $1.name }
    }

    private var ref: DatabaseReference!
    
    var user: User? {
        didSet {
//            updateActiveRooms()
        }
    }

    init() {
        ref = Database.database().reference(withPath: "users")
//        authenticateUser()
        fetchData { [weak self] success in
             if success {
//                 print("Users after fetching: \(self?.users ?? [])")
             } else {
                 print("Failed to fetch users")
             }
         }

         // userプロパティを初期化
         if let currentUserId = currentUserId {
             fetchUserData(userId: currentUserId) { user in
                 self.user = user
//                 self.updateActiveRooms() // userがセットされた後に呼び出す
             }
         }
//        fetchUserRooms { rooms in
//            if let rooms = rooms {
//                // rooms が取得できた時の処理
//                print("Rooms: \(rooms)")
//            } else {
//                // rooms の取得に失敗した時の処理
//                print("Rooms の取得に失敗しました")
//            }
//        }
    }
    
//    func fetchRooms() {
//        let ref = Database.database().reference(withPath: "rooms")
//        ref.observe(.value, with: { snapshot in
//            var newRooms: [Room] = []
//            for child in snapshot.children {
//                if let snapshot = child as? DataSnapshot,
//                   let room = Room(id: UUID().uuidString, name: roomName, userIDs: userIDs)
//            }
//            DispatchQueue.main.async {
//                self.activeRooms = newRooms
//            }
//        })
//    }
    
    func loadData() {
        authenticateUser { [weak self] isAuthenticated in
            if isAuthenticated {
                // 認証成功時の処理
            } else {
                // 認証失敗時の処理
            }
        }
    }

    func authenticateUser(completion: @escaping (Bool) -> Void) {
//        print("teteteststst")
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            if let error = error {
                print("Failed to login or retrieve user:", error.localizedDescription)
                completion(false)  // 認証に失敗した場合は false を渡す
                return
            }
            
            guard let user = authResult?.user else {
                print("Failed to retrieve user after login")
                completion(false)
                return
            }
            
            self?.currentUserId = user.uid
//            print("Current User ID111: \(String(describing: self?.currentUserId))")
            
            self?.fetchData { success in
                if success {
                    print("データの読み込みが成功しました")
                    self?.fetchUserRooms { rooms in
                        if let rooms = rooms {
//                            print("rooms:\(rooms)")
                            self?.activeRooms = rooms.sorted { $0.name < $1.name }
//                            print("Active rooms fetched:", rooms)
                        } else {
                            print("Failed to fetch active rooms")
                        }
                    }
                    completion(true)  // データの読み込みと部屋の取得が成功した場合は true を渡す
                } else {
                    print("データの読み込みに失敗しました")
                    completion(false)
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
//                print("Child snapshot: \(child)")
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: Any],
                   let name = value["name"] as? String,
                   let icon = value["icon"] as? String,
                   let status = value["status"] as? String,
                   let userStatus = UserStatus(rawValue: status) {
                    
                    let user = User(id: childSnapshot.key, name: name, icon: icon, status: userStatus, rooms: [:]) // roomsはここではセットしない
                    newUsers.append(user)
                }
            }
            self?.users = newUsers
//            print("Users after fetching: \(newUsers)")
//            self?.updateActiveRooms()
            completion(true)
        }) { (error) in
            print("Failed to fetch data:", error.localizedDescription)
            completion(false)
        }
    }

    func fetchRoomDetails(roomName: String, completion: @escaping (Room?) -> Void) {
        let roomsRef = Database.database().reference(withPath: "rooms/\(roomName)/members")
        roomsRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let members = snapshot.value as? [String: Bool] else {
                completion(nil)
                return
            }
            let userIDs = Array(members.keys)
            let room = Room(id: UUID().uuidString, name: roomName, members: members, userIDs: userIDs)
            completion(room)
        })
    }

//    func fetchUserRooms(completion: @escaping ([Room]?) -> Void) {
//        guard let userId = self.currentUserId else {
//            print("User is not logged in")
//            completion(nil)
//            return
//        }
//
////        print("Fetching rooms for user ID: \(userId)")
//        
//        ref.child(userId).observeSingleEvent(of: .value, with: { [weak self] snapshot in
////            print("Fetched user data: \(snapshot.value)")
//            
//            // デバッグ: ユーザーのデータ全体をログに出力
////            print("User data for debugging: \(snapshot)")
//
//            guard let value = snapshot.value as? [String: Any] else {
//                print("Could not cast snapshot value to [String: Any]")
//                completion(nil)
//                return
//            }
//
//            // デバッグ: roomsのデータをログに出力
////            print("Rooms data for debugging: \(value["rooms"])")
//
//            guard let roomsDict = value["rooms"] as? [String: Bool] else {
//                print("Could not fetch user's rooms")
//                completion(nil)
//                return
//            }
////            print("roomsDict.keys:\(roomsDict.keys)")
//            let roomNames = Array(roomsDict.keys)
//            
//            var rooms: [Room] = []
//            let group = DispatchGroup()
//            
//            for roomName in roomNames {
//                group.enter()
//                self?.fetchRoomDetails(roomName: roomName) { room in
//                    if let room = room {
//                        rooms.append(room)
//                    }
//                    group.leave()
//                }
//            }
//            
//            group.notify(queue: .main) {
//                completion(rooms)
//            }
//        })
//    }
    
    func fetchUserRooms(completion: @escaping ([Room]?) -> Void) {
        guard let userId = self.currentUserId else {
            print("User is not logged in")
            completion(nil)
            return
        }

        let usersRef = Database.database().reference(withPath: "users")
        usersRef.child(userId).child("rooms").observeSingleEvent(of: .value, with: { [weak self] snapshot in
//            print("snapshot:\(snapshot)")
            guard let roomsStatusDict = snapshot.value as? [String: Bool] else {
                print("Could not fetch user's rooms status")
                completion(nil)
                return
            }

            let activeRoomNames = roomsStatusDict.filter { $0.value == true }.map { $0.key }

            var rooms: [Room] = []
            let group = DispatchGroup()

            for roomName in activeRoomNames {
                group.enter()
                self?.fetchRoomDetails(roomName: roomName) { room in
                    if let room = room {
                        rooms.append(room)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(rooms)
            }
        })
    }



//    func updateActiveRooms() {
//        fetchUserRooms { rooms in
//            self.activeRooms = rooms ?? []
//        }
//    }

    
    func fetchUserData(userId: String, completion: @escaping (User?) -> Void) {
        ref.child(userId).observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let name = value["name"] as? String,
                  let icon = value["icon"] as? String,
                  let status = value["status"] as? String,
                  let userStatus = UserStatus(rawValue: status) else {
                      print("Could not decode user data")
                      completion(nil)
                      return
                  }
            
            // Here, you should extract the rooms as a dictionary of [String: Bool]
            let rooms = value["rooms"] as? [String: Bool] ?? [:]
            
            let user = User(id: snapshot.key, name: name, icon: icon, status: userStatus, rooms: rooms)
            completion(user)
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }

    func searchUserByName(_ name: String) {
//        print("Searching for user with name: \(name)")
//        print("Current users: \(users)")
//        print(users)
        searchedUsers = users.filter { $0.name == name }
        isUserNameTaken = users.contains { $0.name == name }
//        print("Found users: \(searchedUsers)")
//        print("isUserNameTaken:\(isUserNameTaken)")
    }

    func checkIfGroupNameExists(_ groupName: String, completion: @escaping (Bool) -> Void) {
        let roomsRef = Database.database().reference(withPath: "rooms")
        roomsRef.observeSingleEvent(of: .value) { snapshot in
            var exists = false
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   childSnapshot.key != "members", // "members" キーは除外
                   childSnapshot.key == groupName {
                    exists = true
                    break
                }
            }
            completion(exists)
        }
    }
    
    func deleteRoom(withID roomName: String) {
        if let index = activeRooms.firstIndex(where: { $0.name == roomName }) {
            activeRooms.remove(at: index)
            guard let userId = currentUserId else { return }

//            print("roomName:\(roomName)")
//            print("userId:\(userId)")
            let roomsRef = Database.database().reference(withPath: "rooms")
            roomsRef.child(roomName).child("members").child(userId).setValue(false) { error, _ in
                if let error = error {
                    print("部屋の更新中にエラーが発生しました: \(error)")
                } else {
                    print("部屋の値が正常に更新されました。")
                }
            }
            // ユーザーのroomsフィールドの該当部屋IDの値をfalseに更新
            let usersRef = Database.database().reference(withPath: "users")
            usersRef.child(userId).child("rooms").child(roomName).setValue(false) { error, _ in
                if let error = error {
                    print("部屋の更新中にエラーが発生しました: \(error)")
                } else {
                    print("部屋の値が正常に更新されました。")
                }
            }
        }
    }

    func createRoom(withName name: String) {
        if self.currentUserId == nil {
            print("createRoom0")
            authenticateUser { [weak self] isAuthenticated in
                print("createRoom333")
                if isAuthenticated {
                    self?.proceedToCreateRoom(withName: name)
                } else {
                    print("User authentication failed")
                }
            }
        } else {
            proceedToCreateRoom(withName: name)
        }
    }

    func proceedToCreateRoom(withName name: String) {
//        print("createRoom2")
        guard let userId = self.currentUserId else {
//            print("createRoom User is not logged in")
            return
        }
//        print("createRoom1")
        let roomsRef = Database.database().reference(withPath: "rooms/\(name)")
        let userRoomsRef = Database.database().reference(withPath: "users/\(userId)/rooms")
        
        // 部屋を作成
        roomsRef.setValue(["members": [userId: true]]) { [weak self] error, _ in
            if let error = error {
                print("Error creating room: \(error.localizedDescription)")
            } else {
                print("Room created successfully")
                
                // ユーザーの rooms フィールドを更新
                userRoomsRef.updateChildValues([name: true]) { error, _ in
                    if let error = error {
                        print("Error updating user's rooms: \(error.localizedDescription)")
                    } else {
                        print("User's rooms updated successfully")
                        
                        // オプション: 必要に応じて他の処理をここに追加
                    }
                }
            }
        }
    }



    // 指定の部屋にユーザーを追加する機能
    func addUserToRoom(_ user: User, to roomName: String) {
//        print("test2")
        let roomMembersRef = Database.database().reference(withPath: "rooms/\(roomName)/members/\(user.id)")
//        print("test1")
        roomMembersRef.setValue(true) { error, _ in
            if let error = error {
                print("Error adding user to room: \(error.localizedDescription)")
            } else {
                print("User added to room successfully")
            }
        }
    }
    
    func isGroupNameTaken(_ name: String, existingGroups: [String]) -> Bool {
        existingGroups.contains(name)
    }

    func fetchGroupNames() {
        let ref = Database.database().reference(withPath: "rooms")
        ref.observeSingleEvent(of: .value) { snapshot in
            var groups: [String] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   childSnapshot.key != "members" { // "members" キーは除外
                    groups.append(childSnapshot.key)
                }
            }
            DispatchQueue.main.async {
                self.existingGroups = groups
//                print("fetchGroupNames")
//                print(self.existingGroups)
            }
        }
    }
}

