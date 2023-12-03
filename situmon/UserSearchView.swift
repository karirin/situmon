//
//  UserSearchView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/12/03.
//

import SwiftUI
import Firebase

struct UserSearchView: View {
    @State private var inputUserName = ""
    @State private var inputTestUserName = "テストユーザー"
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var selectedRoom: String = ""
    @State private var alertMessage: String = ""
    @State private var hasSearched = false
    @State private var showAlert = false
    @State private var showTestuser = false
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var buttonRect3: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum: Int = 0
    @State private var currentUser: User?
    
    func addUserToRoom(_ user: User, to roomName: String) {
        // 部屋を探す
        if let roomIndex = viewModel.activeRooms.firstIndex(where: { $0.name == roomName }) {
            // ユーザIDが部屋のユーザIDリストに含まれていない場合、追加する
            if !viewModel.activeRooms[roomIndex].members.contains(where: { $0.key == user.id }) {
                fetchRoomStatus0(for: roomName) { status0 in
                    guard let status0Value = status0 else {
                        print("Failed to get status_0 value")
                        return
                    }
                    
                    let userStatusRef = Database.database().reference(withPath: "rooms/\(roomName)/Userstatus/\(user.id)")
                    userStatusRef.setValue(status0Value) { error, _ in
                        if let error = error {
                            print("Error updating user status: \(error.localizedDescription)")
                        } else {
                            print("User status updated successfully")
                        }
                    }
                }
                    
                let roomMembersRef = Database.database().reference(withPath: "rooms/\(roomName)/members/\(user.id)")
                roomMembersRef.setValue(true) { error, _ in
                    if let error = error {
                        print("Error adding user to room: \(error.localizedDescription)")
                    } else {
                        print("User added to room successfully room")
                    }
                }
                let usersRef = Database.database().reference(withPath: "users/\(user.id)/rooms/\(roomName)")
                usersRef.setValue(true) { error, _ in
                    if let error = error {
                        print("Error adding user to room: \(error.localizedDescription)")
                    } else {
                        print("User added to room successfully user")
                    }
                }
                alertMessage = "ユーザーを\(roomName)に追加しました！"
            } else {
                // 既にグループにユーザーが存在する場合
                alertMessage = "このユーザーはすでに\(roomName)に入っています"
            }
            showAlert = true
        } else {
            // 部屋が見つからない場合のエラーメッセージ
            alertMessage = "\(roomName)は存在しません"
            showAlert = true
        }
    }

    func fetchRoomStatus0(for roomName: String, completion: @escaping (String?) -> Void) {
        let statusRef = Database.database().reference(withPath: "rooms/\(roomName)/statuses/status_0")
        statusRef.observeSingleEvent(of: .value, with: { snapshot in
            let status0 = snapshot.value as? String
            completion(status0)
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }

    // ユーザーを部屋に追加するボタンのアクション
    var addUserToRoomAction: () -> Void {
        print("addUserToRoomAction1")
        return {
            guard let user = viewModel.searchedUsers.first else { print("return")
                return }
            print("addUserToRoomAction2")
            addUserToRoom(user, to: selectedRoom)
        }
    }
    
    var body: some View {
        ZStack{
            NavigationView {
                VStack {
                    HStack{
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.black)
                                Text("戻る")
                                    .foregroundColor(.black)
                                    .font(.body)
                                Spacer()
                            }
                            .padding()
                        }
                        Spacer()
                    }
                    ScrollView{
//                        if showTestuser == false {
                            VStack{
                                HStack {
                                    Text("ユーザー名を入力してください")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("fontGray"))
                                }
                                Text("グループに追加するユーザーを検索します")
                                    .font(.system(size: 18))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                ZStack(alignment: .trailing){
                                    TextField("ユーザー名", text: $inputUserName)
                                        .frame(width:.infinity)
                                        .onChange(of: inputUserName) { newValue in
                                            if newValue.count > 20 {
                                                inputUserName = String(newValue.prefix(20))
                                            }
                                        }
                                        .font(.system(size: 35))
                                        .background(GeometryReader { geometry in
                                            Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                                        })
                                        .padding(.trailing, inputUserName.isEmpty ? 0 : 40)
                                    if !inputUserName.isEmpty {
                                        Button(action: {
                                            self.inputUserName = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .font(.system(size: 30))
                                        .padding(.trailing, 5)
                                    }
                                }
                                .padding()
                                
                                Button(action: {
                                    viewModel.searchUserByName(inputUserName)
                                    inputUserName = ""
                                    hasSearched = true
                                    if tutorialNum == 77 {
                                        showTestuser = true
                                    }
                                }) {
                                    Text("ユーザー名を検索")
                                        .padding(.vertical,10)
                                        .padding(.horizontal,25)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .fill(inputUserName.isEmpty ? Color.gray : Color("btnColor")))
                                        .opacity(inputUserName.isEmpty ? 0.5 : 1.0)
                                        .padding()
                                    
                                }
                                .disabled(inputUserName.isEmpty)
                                Spacer()
                                if hasSearched && viewModel.searchedUsers.isEmpty {
                                    Text("ユーザーが見つかりませんでした")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                } else {
                                    ForEach(viewModel.searchedUsers) { user in
                                        VStack {
                                            if user.id == viewModel.currentUserId {
                                                Text("こちらはあなたのユーザー名です")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.gray)
                                            } else {
                                                VStack{
                                                    Text("こちらの方でしょうか？")
                                                        .font(.system(size: 30))
                                                        .foregroundColor(.gray)
                                                    HStack{
                                                        Image(user.icon)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 80, height: 80)
                                                            .clipShape(Circle())
                                                            .padding(.trailing)
                                                        Text(user.name)
                                                            .font(.system(size: 40))
                                                    }
                                                }
                                                .background(GeometryReader { geometry in
                                                    Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
                                                })
                                                VStack{
                                                    Text("追加先のグループを選択してください")
                                                        .font(.system(size: 20))
                                                    Picker("", selection: $selectedRoom) {
                                                        ForEach(getUserRooms(), id: \.self) { roomName in
                                                            Text(roomName).tag(roomName)
                                                                .font(.system(size: 40))
                                                        }
                                                    }
                                                    .onAppear {
                                                        viewModel.authenticateUser { isAuthenticated in
                                                            if isAuthenticated {
                                                                // 認証成功時の処理
                                                                print("認証に成功しました")
                                                                //                                                print(user)
                                                            } else {
                                                                // 認証失敗時の処理
                                                            }
                                                        }
                                                        let rooms = getUserRooms()
                                                        if !rooms.isEmpty {
                                                            selectedRoom = rooms[0]
                                                        }
                                                    }
                                                    .pickerStyle(MenuPickerStyle()) // メニュー形式のピッカーにする
                                                    .accentColor(Color("fontGray"))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 100)
                                                            .stroke(.black.opacity(3), lineWidth: 1)
                                                    )
                                                }
                                                .background(GeometryReader { geometry in
                                                    Color.clear.preference(key: ViewPositionKey2.self, value: [geometry.frame(in: .global)])
                                                })
                                                .padding()
                                                Button(action: addUserToRoomAction) {
                                                    Text("ユーザーをグループに追加")
                                                        .padding(.vertical, 10)
                                                        .padding(.horizontal, 25)
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                        .background(RoundedRectangle(cornerRadius: 25)
                                                            .fill(selectedRoom.isEmpty ? Color.gray : Color("btnColor")))
                                                        .opacity(selectedRoom.isEmpty ? 0.5 : 1.0)
                                                        .padding()
                                                }
                                                .alert(isPresented: $showAlert) {
                                                    Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                                                }
                                                
                                            }
                                        }
                                        .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
//                    else {
//                            VStack{
//                                HStack {
//                                    Text("ユーザー名を入力してください")
//                                        .font(.system(size: 24))
//                                        .foregroundColor(Color("fontGray"))
//                                }
//                                Text("グループに追加するユーザーを検索します")
//                                    .font(.system(size: 18))
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                    .multilineTextAlignment(.center)
//                                    .padding(.horizontal)
//                                    .padding(.top, 5)
//                                ZStack(alignment: .trailing){
//                                    TextField("ユーザー名", text: $inputTestUserName)
//                                        .frame(width:.infinity)
//                                        .onChange(of: inputTestUserName) { newValue in
//                                            if newValue.count > 20 {
//                                                inputTestUserName = String(newValue.prefix(20))
//                                            }
//                                        }
//                                        .font(.system(size: 35))
//                                        .background(GeometryReader { geometry in
//                                            Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
//                                        })
//                                        .padding(.trailing, inputTestUserName.isEmpty ? 0 : 40)
//                                    if !inputTestUserName.isEmpty {
//                                        Button(action: {
//                                            self.inputTestUserName = ""
//                                        }) {
//                                            Image(systemName: "xmark.circle.fill")
//                                                .foregroundColor(.gray)
//                                        }
//                                        .font(.system(size: 30))
//                                        .padding(.trailing, 5)
//                                    }
//                                }
//                                .padding()
//                                
//                                Button(action: {
//                                    viewModel.searchUserByName(inputTestUserName)
//                                    inputTestUserName = ""
//                                    hasSearched = true
//                                    if tutorialNum == 66 {
//                                        showTestuser = true
//                                    }
//                                    print("searchedUsers")
//                                    print(viewModel.searchedUsers)
//                                }) {
//                                    Text("ユーザー名を検索")
//                                        .padding(.vertical,10)
//                                        .padding(.horizontal,25)
//                                        .font(.headline)
//                                        .foregroundColor(.white)
//                                        .background(RoundedRectangle(cornerRadius: 25)
//                                            .fill(inputTestUserName.isEmpty ? Color.gray : Color("btnColor")))
//                                        .opacity(inputTestUserName.isEmpty ? 0.5 : 1.0)
//                                        .padding()
//                                    
//                                }
//                                .disabled(inputTestUserName.isEmpty)
//                                Spacer()
//                                if hasSearched && viewModel.searchedUsers.isEmpty {
//                                    Text("ユーザーが見つかりませんでした")
//                                        .font(.system(size: 20))
//                                        .foregroundColor(.gray)
//                                        .padding(.top, 20)
//                                } else {
//                                    ForEach(viewModel.searchedUsers) { user in
//                                        VStack {
//                                            if user.id == viewModel.currentUserId {
//                                                Text("こちらはあなたのユーザー名です")
//                                                    .font(.system(size: 30))
//                                                    .foregroundColor(.gray)
//                                            } else {
//                                                VStack{
//                                                    Text("こちらの方でしょうか？")
//                                                        .font(.system(size: 30))
//                                                        .foregroundColor(.gray)
//                                                    HStack{
//                                                        Image(user.icon)
//                                                            .resizable()
//                                                            .scaledToFit()
//                                                            .frame(width: 80, height: 80)
//                                                            .clipShape(Circle())
//                                                            .padding(.trailing)
//                                                        Text(user.name)
//                                                            .font(.system(size: 40))
//                                                    }
//                                                }
//                                                .background(GeometryReader { geometry in
//                                                    Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
//                                                })
//                                                VStack{
//                                                    Text("追加先のグループを選択してください")
//                                                        .font(.system(size: 20))
//                                                    Picker("", selection: $selectedRoom) {
//                                                        ForEach(getUserRooms(), id: \.self) { roomName in
//                                                            Text(roomName).tag(roomName)
//                                                                .font(.system(size: 40))
//                                                        }
//                                                    }
//                                                    .onAppear {
//                                                        viewModel.authenticateUser { isAuthenticated in
//                                                            if isAuthenticated {
//                                                                // 認証成功時の処理
//                                                                print("認証に成功しました")
//                                                                //                                                print(user)
//                                                            } else {
//                                                                // 認証失敗時の処理
//                                                            }
//                                                        }
//                                                        let rooms = getUserRooms()
//                                                        if !rooms.isEmpty {
//                                                            selectedRoom = rooms[0]
//                                                            //                                            print("selectedRoom:\(selectedRoom)")
//                                                        }
//                                                    }
//                                                    .pickerStyle(MenuPickerStyle()) // メニュー形式のピッカーにする
//                                                    .accentColor(Color("fontGray"))
//                                                    .overlay(
//                                                        RoundedRectangle(cornerRadius: 100)
//                                                            .stroke(.black.opacity(3), lineWidth: 1)
//                                                    )
//                                                }
//                                                .background(GeometryReader { geometry in
//                                                    Color.clear.preference(key: ViewPositionKey2.self, value: [geometry.frame(in: .global)])
//                                                })
//                                                .padding()
//                                                Button(action: addUserToRoomAction) {
//                                                    Text("ユーザーをグループに追加")
//                                                        .padding(.vertical, 10)
//                                                        .padding(.horizontal, 25)
//                                                        .font(.headline)
//                                                        .foregroundColor(.white)
//                                                        .background(RoundedRectangle(cornerRadius: 25)
//                                                            .fill(selectedRoom.isEmpty ? Color.gray : Color("btnColor")))
//                                                        .opacity(selectedRoom.isEmpty ? 0.5 : 1.0)
//                                                        .padding()
//                                                }
//                                                //                                                            .disabled(selectedRoom.isEmpty)
//                                                .alert(isPresented: $showAlert) {
//                                                    Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//                                                }
//                                                
//                                            }
//                                        }
//                                        .padding(.bottom, 10)
//                                    }
//                                    .onAppear{
//                                        let user1 = User(id: "qtfVZGkjcIP0YTIGGFZSp7g8CmB5", name: "テストユーザー", icon: "user2",rooms: [:], tutorialNum: 1)
//                                        viewModel.searchedUsers = [user1]
//                                    }
//                                }
//                            }
//                        }
//                    }
                    
                    Spacer()
                    Spacer()
                }
            }
            .onAppear{

                if showTestuser == false {
                    hasSearched = false
                }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        print(currentUser)
                        // 認証成功時の処理
                        print("認証に成功しました")
//                        if currentUser!.tutorialNum == 5 || currentUser!.tutorialNum == 6{
//                            self.tutorialNum = currentUser!.tutorialNum
//                        }
                    } else {
                        // 認証失敗時の処理
                        print("認証失敗")
                    }
                }
            }
//            .onPreferenceChange(ViewPositionKey.self) { positions in
//                self.buttonRect = positions.first ?? .zero
//            }
//            .onPreferenceChange(ViewPositionKey1.self) { positions in
//                self.buttonRect2 = positions.first ?? .zero
//            }
//            .onPreferenceChange(ViewPositionKey2.self) { positions in
//                self.buttonRect3 = positions.first ?? .zero
//            }
            Spacer()
//            if tutorialNum == 5 {
//                GeometryReader { geometry in
//                    Color.black.opacity(0.5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                .frame(width: buttonRect.width, height: buttonRect.height + 10)
//                                .position(x: buttonRect.midX - 10, y: buttonRect.midY)
//                                .blendMode(.destinationOut)
//                        )
//                        .ignoresSafeArea()
//                        .compositingGroup()
//                        .background(.clear)
//                }
//                VStack {
//                    Spacer()
//                        .frame(height: buttonRect.minY - bubbleHeight)
//                    VStack(alignment: .trailing, spacing: .zero) {
//                        Text("追加したいユーザー名を入力します。\n今回は「テストユーザー」と入力しましょう。")
//                            .font(.system(size: 20.0))
//                            .padding(.all, 10.0)
//                            .background(Color.white)
//                            .cornerRadius(4.0)
//                            .padding(.horizontal, 3)
//                            .foregroundColor(Color("fontGray"))
//                        Image("下矢印")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .padding(.trailing, 45.0)
//                    }
//                    .background(GeometryReader { geometry in
//                        Path { _ in
//                            DispatchQueue.main.async {
//                                self.bubbleHeight = geometry.size.height + 20
//                            }
//                        }
//                    })
//                    Spacer()
//                }
//                .ignoresSafeArea()
//                            }
//            if tutorialNum == 6 {
//                GeometryReader { geometry in
//                    Color.black.opacity(0.5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                .frame(width: buttonRect2.width, height: buttonRect2.height + 10)
//                                .position(x: buttonRect2.midX, y: buttonRect2.midY)
//                                .blendMode(.destinationOut)
//                        )
//                        .ignoresSafeArea()
//                        .compositingGroup()
//                        .background(.clear)
//                }
//                VStack {
//                    Spacer()
//                        .frame(height: buttonRect2.minY - bubbleHeight)
//                    VStack(alignment: .trailing, spacing: .zero) {
//                        Text("「テストユーザー」が検索結果にヒットします。\n先ほど登録したグループを選択して「テストユーザー」を追加します。")
//                            .font(.system(size: 20.0))
//                            .padding(.all, 10.0)
//                            .background(Color.white)
//                            .cornerRadius(4.0)
//                            .padding(.horizontal, 3)
//                            .foregroundColor(Color("fontGray"))
//                        Image("下矢印")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .padding(.trailing, 45.0)
//                    }
//                    .background(GeometryReader { geometry in
//                        Path { _ in
//                            DispatchQueue.main.async {
//                                self.bubbleHeight = geometry.size.height + 20
//                            }
//                        }
//                    })
//                    Spacer()
//                }
//                .ignoresSafeArea()
//                            }
        }
//        .onTapGesture {
//            print("onTapGestureaaa")
//            if self.tutorialNum == 5 {
//                tutorialNum = 66
//                hasSearched = true
//            }
//            else if showTestuser == true {
//                self.tutorialNum = 0 // タップでチュートリアルを終了
//                viewModel.authenticateUser { isAuthenticated in
//                    if isAuthenticated {
//                        viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 6) { success in
//                            // データベースのアップデートが成功したかどうかをハンドリング
//                        }
//                    }
//                }
//            }
//        }
    }
    func getUserRooms() -> [String] {
        // 現在のユーザIDを確認
        guard let currentUserId = viewModel.currentUserId else {  print("return"); return [] }
        // アクティブな部屋をフィルタリングして、部屋の名前の配列を返す
        return viewModel.activeRooms.filter { room in
            return room.members.contains(where: { $0.key == currentUserId })
        }.map { $0.name }.sorted()
    }
}

#Preview {
    UserSearchView()
}
