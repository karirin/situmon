//
//  AuthManager.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/11/17.
//

import SwiftUI
import Firebase

struct User: Identifiable {
    var id: String
    var name: String
    var icon: String
    var rooms: [String: Bool]
    var tutorialNum: Int
    
    func activeRoomIDs() -> [String] {
        return rooms.filter { $0.value }.map { $0.key }
    }
}

class AuthManager: ObservableObject {
    @Published var user: User?
    static let shared = AuthManager()
    private var ref: DatabaseReference = Database.database().reference(withPath: "users")
    
    init() {
        anonymousSignIn()
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        ref.child(firebaseUser.uid).observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let name = value["name"] as? String,
                  let icon = value["icon"] as? String,
                  let status = value["status"] as? String,
                  let tutorialNum = value["tutorialNum"] as? Int,
                  let userStatus = UserStatus(rawValue: status) else {
                      print("Could not decode user data")
//                      completion(nil)
                      return
                  }
            
            // Here, you should extract the rooms as a dictionary of [String: Bool]
            let rooms = value["rooms"] as? [String: Bool] ?? [:]
            
            let user = User(id: snapshot.key, name: name, icon: icon, rooms: rooms, tutorialNum: tutorialNum)
//            completion(user)
        }) { error in
            print(error.localizedDescription)
//            completion(nil)
        }
    }

    func fetchCurrentUser(completion: @escaping (User?) -> Void) {
            guard let firebaseUser = Auth.auth().currentUser else {
                print("現在ログインしているユーザーはいません。")
                completion(nil)
                return
            }

            ref.child(firebaseUser.uid).observeSingleEvent(of: .value, with: { snapshot in
                guard let value = snapshot.value as? [String: Any],
                      let name = value["name"] as? String,
                      let icon = value["icon"] as? String,
                      let rooms = value["rooms"] as? [String: Bool],
                      let tutorialNum = value["tutorialNum"] as? Int else {
                    print("ユーザーデータの取得に失敗しました。")
                    completion(nil)
                    return
                }

                let user = User(id: snapshot.key, name: name, icon: icon, rooms: rooms, tutorialNum: tutorialNum)
                completion(user)
            }) { error in
                print(error.localizedDescription)
                completion(nil)
            }
        }
    
    func anonymousSignIn() {
           Auth.auth().signInAnonymously { [weak self] authResult, error in
               guard let self = self else { return }
               
               if let error = error {
                   print("匿名サインインに失敗しました: \(error)")
                   return
               }
               guard let user = authResult?.user else {
                   print("ユーザー情報を取得できませんでした。")
                   return
               }
               
               // 成功した場合、ユーザーデータを取得
               self.fetchUserData()
           }
       }
}
