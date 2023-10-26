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

    private var ref: DatabaseReference!
    
    var user: User? {
        didSet {
            updateActiveRooms()
        }
    }

    init() {
        ref = Database.database().reference(withPath: "users")
        authenticateUser()
        self.users = users

         // userプロパティを初期化
         if let currentUserId = currentUserId {
             fetchUserData(userId: currentUserId) { user in
                 self.user = user
                 self.updateActiveRooms() // userがセットされた後に呼び出す
             }
         }
        fetchUserRooms { rooms in
            if let rooms = rooms {
                // rooms が取得できた時の処理
                print("Rooms: \(rooms)")
            } else {
                // rooms の取得に失敗した時の処理
                print("Rooms の取得に失敗しました")
            }
        }
    }
    
    func loadData() {
        authenticateUser()
    }

    func authenticateUser() {
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            guard let user = authResult?.user else {
                print("Failed to login or retrieve user: \(error?.localizedDescription ?? "")")
                return
            }
            self?.currentUserId = user.uid
            self?.fetchData { success in
                if success {
                    print("データの読み込みが成功しました")
                } else {
                    print("データの読み込みに失敗しました")
                }
            }
            self?.fetchUserRooms { rooms in
                if let rooms = rooms {
                    // rooms が取得できた時の処理
                    print("Rooms: \(rooms)")
                } else {
                    // rooms の取得に失敗した時の処理
                    print("Rooms の取得に失敗しました")
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
                    
                    let user = User(id: childSnapshot.key, name: name, icon: icon, status: userStatus, rooms: rooms)
                    newUsers.append(user)
                }
                if let strongSelf = self, let currentUserId = strongSelf.currentUserId {
                    strongSelf.fetchUserData(userId: currentUserId) { user in
                        strongSelf.user = user
                        strongSelf.updateActiveRooms()
                    }
                }
            }
            self?.users = newUsers
            self?.updateActiveRooms()
            completion(true) // 読み込みが成功したらtrueを渡してコンプリーションハンドラを呼び出す
        }) { (error) in
            print("Failed to fetch data:", error.localizedDescription)
            completion(false) // エラーが発生したらfalseを渡してコンプリーションハンドラを呼び出す
        }
    }
    
    func fetchUserRooms(completion: @escaping ([Room]?) -> Void) {
        guard let userId = self.currentUserId else {
            print("currentUserId is nil")
            completion(nil)
            return
        }

        let userRoomsRef = Database.database().reference(withPath: "users/\(userId)/rooms")
        userRoomsRef.observe(.value, with: { [weak self] snapshot in
            print("Snapshot received: \(snapshot)")

            guard let roomNames = snapshot.value as? [String: Bool] else {
                print("Failed to cast snapshot value to [String: Bool]")
                completion(nil)
                return
            }

            let group = DispatchGroup()
            var rooms: [Room] = []

            for (roomName, _) in roomNames {
                group.enter()
                self?.fetchRoomDetails(roomName: roomName, completion: { room in
                    defer { group.leave() }

                    if let room = room {
                        rooms.append(room)
                    } else {
                        print("Failed to fetch details for room: \(roomName)")
                    }
                })
            }

            group.notify(queue: .main) {
                self?.activeRooms = rooms
                print("activeRooms updated: \(self?.activeRooms)")
                completion(rooms)
            }
        })
    }


    func fetchRoomDetails(roomName: String, completion: @escaping (Room?) -> Void) {
        ref.observeSingleEvent(of: .value, with: { snapshot in
            var userIDs: [String] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: Any],
                   let rooms = value["rooms"] as? [String: Bool],
                   rooms[roomName] == true {
//                    print("rooms")
//                    print(rooms)
                    userIDs.append(childSnapshot.key)
                }
            }
            
            if userIDs.isEmpty {
                completion(nil)
            } else {
                let room = Room(id: UUID().uuidString, name: roomName, userIDs: userIDs)
                completion(room)
            }
        })
    }


    func updateActiveRooms() {
        activeRooms = rooms.filter { room in
            user?.rooms[room.name] == true
        }
    }
    
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
        searchedUsers = users.filter { $0.name == name }
    }

    func createRoom(withName name: String) {
        // 部屋をroomsに追加する
        let newRoom = Room(id: UUID().uuidString, name: name, userIDs: [])
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
            let newRoom = Room(id: UUID().uuidString, name: roomName, userIDs: [user.id])
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

