//
//  RegisterView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/20.
//

import SwiftUI
import Firebase

struct User: Identifiable {
    var id: String
    var name: String
    var icon: String
    var status: UserStatus
    var rooms: [String: Bool]
    
    func activeRoomIDs() -> [String] {
        return rooms.filter { $0.value }.map { $0.key }
    }
}

class FirebaseService {
    
    private var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    func currentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func registerUser(user: User, completion: @escaping (Error?) -> Void) {
        let usersRef = databaseRef.child("users").child(user.id)
        let userDict: [String: Any] = [
            "name": user.name,
            "icon": user.icon,
            "status": "質問して大丈夫です",
            "rooms": user.rooms ?? [:]  // ここで空の辞書を設定
        ]
        usersRef.setValue(userDict) { error, _ in
            completion(error)
        }
    }

}

struct NameInputView: View {
    @Binding var userName: String
    
    var body: some View {
        VStack {
            HStack {
                Text("名前を入力してください")
                    .font(.system(size: 30))
                    .foregroundColor(Color("fontGray"))
            }
            Text("20文字以下で入力してください")
                .font(.system(size: 18))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
            ZStack(alignment: .trailing) {
                TextField("名前", text: $userName)
                    .onChange(of: userName) { newValue in
                        if newValue.count > 20 {
                            userName = String(newValue.prefix(20))
                        }
                    }
                    .font(.system(size: 35))
                    .padding(.trailing, userName.isEmpty ? 0 : 40)
                
                if !userName.isEmpty {
                    Button(action: {
                        self.userName = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .font(.system(size: 30))
                    .padding(.trailing, 5)
                }
            }
            .padding()
        }
    }
}

struct IconSelectionView: View {
    @Binding var selectedIcon: String
    let icons: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("アイコンを選択してください")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(Color("fontGray"))
            }
            ForEach(0..<icons.count / 3) { rowIndex in
                HStack(spacing: 20) {
                    ForEach(0..<3) { colIndex in
                        let iconIndex = rowIndex * 3 + colIndex
                        if iconIndex < icons.count {
                            Button(action: {
                                self.selectedIcon = icons[iconIndex]
                            }) {
                                Image(icons[iconIndex])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(self.selectedIcon == icons[iconIndex] ? Color.blue : Color.clear, lineWidth: 3)
                                            .padding(-5)
                                    )
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
    }
}

struct NameInputPage: View {
    @Binding var userName: String
    
    var body: some View {
        VStack {
            NameInputView(userName: $userName)
            
            NavigationLink(destination: IconSelectionPage(userName: $userName)) {
                ZStack {
                    // ボタンの背景
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .frame(width: 140, height: 70)
                        .shadow(radius: 3) // ここで影をつけます
                    Text("次へ")
                }
                    .font(.system(size:26))
                    .foregroundColor(Color.gray)
                        .disabled(userName.isEmpty)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(userName.isEmpty ? Color.gray : Color.white))
                        .opacity(userName.isEmpty ? 0.5 : 1.0)
            }
            .disabled(userName.isEmpty)
        }
    }
}

struct IconSelectionPage: View {
    @Binding var userName: String
    @State private var selectedIcon: String = "user1"
    private let icons = ["user1", "user2", "user3", "user4", "user5","user6", "user7", "user8", "user9", "user10"]
    private let firebaseService = FirebaseService()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
            VStack {
                IconSelectionView(selectedIcon: $selectedIcon, icons: icons)
                    .padding(.bottom)
                Button(action: {
                    let icon = selectedIcon
                    
                    // FirebaseからのユーザーIDを使用してユーザーデータを保存
                    if let userId = firebaseService.currentUserId() {
                        let user = User(id: userId, name: userName, icon: icon, status: .available, rooms: [:])
                        firebaseService.registerUser(user: user) { error in
                            if let error = error {
                                print("Error registering user: \(error.localizedDescription)")
                            } else {
                                print("User registered successfully!")
                            }
                        }
                    } else {
                        print("No user is currently logged in.")
                    }
            }) {
                ZStack {
                // ボタンの背景
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(width: 300, height: 70)
                    .shadow(radius: 3) // ここで影をつけます
                Text("登録")
                    .shadow(radius: 0)
            }
                }
            .font(.system(size:26))
            .foregroundColor(Color.gray)
            .background(RoundedRectangle(cornerRadius: 25))
                        
                        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
            Text("戻る")
                .foregroundColor(.black)
        })
    }
}

struct RegisterView: View {
    @State private var userName: String = ""
    
    var body: some View {
        NavigationView {
            NameInputPage(userName: $userName)
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
