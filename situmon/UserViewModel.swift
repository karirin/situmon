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
    @Published var isLoading: Bool = false
    
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
        isLoading = true
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
//                 print("useraaaa:\(self.user)")
//                 self.updateActiveRooms() // userがセットされた後に呼び出す
             }
         }
    }
    
    
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
                   let tutorialNum = value["tutorialNum"] as? Int,
                   let icon = value["icon"] as? String {
                    
                    let user = User(id: childSnapshot.key, name: name, icon: icon, rooms: [:], tutorialNum: tutorialNum) // roomsはここではセットしない
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
    
    func updateTutorialNum(userId: String, tutorialNum: Int, completion: @escaping (Bool) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        let updates = ["tutorialNum": tutorialNum]
        userRef.updateChildValues(updates) { (error, _) in
            if let error = error {
                print("Error updating tutorialNum: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func fetchRoomDetails(roomName: String, completion: @escaping (Room?) -> Void) {
        let roomRef = Database.database().reference(withPath: "rooms/\(roomName)")
        roomRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let roomDict = snapshot.value as? [String: Any],
                  let members = roomDict["members"] as? [String: Bool],
                  let StatusStrings = roomDict["statuses"] as? [String: String],
                  let userStatusStrings = roomDict["Userstatus"] as? [String: String] else {
                print("fetchRoomDetails flase")
                completion(nil)
                return
            }

            let userIDs = Array(members.keys)
            let userStatuses = userStatusStrings.compactMapValues { UserStatus(rawValue: $0) } // StringからUserStatusへ変換

            let room = Room(id: UUID().uuidString, name: roomName, members: members, statuses: StatusStrings, userStatuses: userStatuses)
//            print("fetchRoomDetails room:\(room)")
            completion(room)
        })
    }
    
    func fetchUserRooms(completion: @escaping ([Room]?) -> Void) {
        guard let userId = self.currentUserId else {
            print("User is not logged in")
            completion(nil)
            return
        }

        let usersRef = Database.database().reference(withPath: "users")
        usersRef.child(userId).child("rooms").observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
//                        print("rooms:\(rooms)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(rooms)
            }
        })
    }
    
    func fetchUserData(userId: String, completion: @escaping (User?) -> Void) {
        ref.child(userId).observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let name = value["name"] as? String,
                  let icon = value["icon"] as? String,
                  let status = value["status"] as? String,
                  let tutorialNum = value["tutorialNum"] as? Int,
                  let userStatus = UserStatus(rawValue: status) else {
                      print("Could not decode user data")
                      completion(nil)
                      return
                  }
            
            // Here, you should extract the rooms as a dictionary of [String: Bool]
            let rooms = value["rooms"] as? [String: Bool] ?? [:]
            
            let user = User(id: snapshot.key, name: name, icon: icon, rooms: rooms, tutorialNum: tutorialNum)
            completion(user)
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }

    func searchUserByName(_ name: String) {
        print("users:\(users)")
        searchedUsers = users.filter { $0.name == name }
        isUserNameTaken = users.contains { $0.name == name }
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

    func createRoom(withName name: String, statuses: [String], userStatuses: [String]) {
        if self.currentUserId == nil {
            print("User is not logged in")
            authenticateUser { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.proceedToCreateRoom(withName: name, inputStatuses: statuses)
                } else {
                    print("User authentication failed")
                }
            }
        } else {
            proceedToCreateRoom(withName: name, inputStatuses: statuses)
        }
    }

    func proceedToCreateRoom(withName name: String, inputStatuses: [String]) {
        guard let userId = self.currentUserId else {
            return
        }

        let roomsRef = Database.database().reference(withPath: "rooms/\(name)")
        let userRoomsRef = Database.database().reference(withPath: "users/\(userId)/rooms")

        var statusesDict = [String: String]()
        for (index, status) in inputStatuses.enumerated() {
            let statusKey = "status_\(index)" // ユニークなキーを作成
            statusesDict[statusKey] = status
        }

        var userStatusesDict = [String: String]()
        let firstStatus = inputStatuses.first ?? "" // 最初のステータスを取得、空の場合は空文字列を使用
        userStatusesDict[userId] = firstStatus

        let newRoomData = [
            "members": [userId: true],
            "statuses": statusesDict,
            "Userstatus": userStatusesDict // 最初のステータスを設定
        ] as [String : Any]

        roomsRef.setValue(newRoomData) { error, _ in
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
                   }
               }
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

