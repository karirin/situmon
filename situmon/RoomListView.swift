//
//  roomListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
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
//            selectedRoom = "" // 部屋を追加した後は選択をクリア
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
                        if showTestuser == false {
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
                                    //                                if self.tutorialNum == 77 {
                                    //                                    self.tutorialNum = 7 // タップでチュートリアルを終了
                                    //                                    print("currentUser?.id:\(currentUser?.id)")
                                    //                                    viewModel.authenticateUser { isAuthenticated in
                                    //                                        if isAuthenticated {
                                    //                                            viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 7) { success in
                                    //                                                // データベースのアップデートが成功したかどうかをハンドリング
                                    //                                            }
                                    //                                        }
                                    //                                    }
                                    //                                }
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
                                                            //                                            print("selectedRoom:\(selectedRoom)")
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
                                                //                                                            .disabled(selectedRoom.isEmpty)
                                                .alert(isPresented: $showAlert) {
                                                    Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                                                }
                                                
                                            }
                                        }
                                        .padding(.bottom, 10)
                                    }
                                }
                            }
                        } else {
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
                                    TextField("ユーザー名", text: $inputTestUserName)
                                        .frame(width:.infinity)
                                        .onChange(of: inputTestUserName) { newValue in
                                            if newValue.count > 20 {
                                                inputTestUserName = String(newValue.prefix(20))
                                            }
                                        }
                                        .font(.system(size: 35))
                                        .background(GeometryReader { geometry in
                                            Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                                        })
                                        .padding(.trailing, inputTestUserName.isEmpty ? 0 : 40)
                                    if !inputTestUserName.isEmpty {
                                        Button(action: {
                                            self.inputTestUserName = ""
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
                                    viewModel.searchUserByName(inputTestUserName)
                                    inputTestUserName = ""
                                    hasSearched = true
                                    if tutorialNum == 66 {
                                        showTestuser = true
                                    }
                                    print("searchedUsers")
                                    print(viewModel.searchedUsers)
                                }) {
                                    Text("ユーザー名を検索")
                                        .padding(.vertical,10)
                                        .padding(.horizontal,25)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .fill(inputTestUserName.isEmpty ? Color.gray : Color("btnColor")))
                                        .opacity(inputTestUserName.isEmpty ? 0.5 : 1.0)
                                        .padding()
                                    
                                }
                                .disabled(inputTestUserName.isEmpty)
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
                                                            //                                            print("selectedRoom:\(selectedRoom)")
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
                                                //                                                            .disabled(selectedRoom.isEmpty)
                                                .alert(isPresented: $showAlert) {
                                                    Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                                                }
                                                
                                            }
                                        }
                                        .padding(.bottom, 10)
                                    }
                                    .onAppear{
                                        let user1 = User(id: "qtfVZGkjcIP0YTIGGFZSp7g8CmB5", name: "テストユーザー", icon: "user2",rooms: [:], tutorialNum: 1)
                                        viewModel.searchedUsers = [user1]
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
            .onAppear{

                if showTestuser == false {
                    print("|||||||||||||")
                    hasSearched = false
                }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        print(currentUser)
                        // 認証成功時の処理
                        print("認証に成功しました")
                        if currentUser!.tutorialNum == 5 || currentUser!.tutorialNum == 6{
                            self.tutorialNum = currentUser!.tutorialNum
                        }
                    } else {
                        // 認証失敗時の処理
                        print("認証失敗")
                    }
                }
            }
            .onPreferenceChange(ViewPositionKey.self) { positions in
                self.buttonRect = positions.first ?? .zero
            }
            .onPreferenceChange(ViewPositionKey1.self) { positions in
                self.buttonRect2 = positions.first ?? .zero
            }
            .onPreferenceChange(ViewPositionKey2.self) { positions in
                self.buttonRect3 = positions.first ?? .zero
            }
            Spacer()
            if tutorialNum == 5 {
                GeometryReader { geometry in
                    Color.black.opacity(0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .frame(width: buttonRect.width, height: buttonRect.height + 10)
                                .position(x: buttonRect.midX - 10, y: buttonRect.midY)
                                .blendMode(.destinationOut)
                        )
                        .ignoresSafeArea()
                        .compositingGroup()
                        .background(.clear)
                }
                VStack {
                    Spacer()
                        .frame(height: buttonRect.minY - bubbleHeight)
                    VStack(alignment: .trailing, spacing: .zero) {
                        Text("追加したいユーザー名を入力します。\n今回は「テストユーザー」と入力しましょう。")
                            .font(.system(size: 20.0))
                            .padding(.all, 10.0)
                            .background(Color.white)
                            .cornerRadius(4.0)
                            .padding(.horizontal, 3)
                            .foregroundColor(Color("fontGray"))
                        Image("下矢印")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 45.0)
                    }
                    .background(GeometryReader { geometry in
                        Path { _ in
                            DispatchQueue.main.async {
                                self.bubbleHeight = geometry.size.height + 20
                            }
                        }
                    })
                    Spacer()
                }
                .ignoresSafeArea()
                            }
            if tutorialNum == 6 {
                GeometryReader { geometry in
                    Color.black.opacity(0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .frame(width: buttonRect2.width, height: buttonRect2.height + 10)
                                .position(x: buttonRect2.midX, y: buttonRect2.midY)
                                .blendMode(.destinationOut)
                        )
                        .ignoresSafeArea()
                        .compositingGroup()
                        .background(.clear)
                }
                VStack {
                    Spacer()
                        .frame(height: buttonRect2.minY - bubbleHeight)
                    VStack(alignment: .trailing, spacing: .zero) {
                        Text("「テストユーザー」が検索結果にヒットします。\n先ほど登録したグループを選択して「テストユーザー」を追加します。")
                            .font(.system(size: 20.0))
                            .padding(.all, 10.0)
                            .background(Color.white)
                            .cornerRadius(4.0)
                            .padding(.horizontal, 3)
                            .foregroundColor(Color("fontGray"))
                        Image("下矢印")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 45.0)
                    }
                    .background(GeometryReader { geometry in
                        Path { _ in
                            DispatchQueue.main.async {
                                self.bubbleHeight = geometry.size.height + 20
                            }
                        }
                    })
                    Spacer()
                }
                .ignoresSafeArea()
                            }
//            if tutorialNum == 8 {
//                GeometryReader { geometry in
//                    Color.black.opacity(0.5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                .frame(width: buttonRect3.width + 10, height: buttonRect3.height + 10)
//                                .position(x: buttonRect3.midX, y: buttonRect3.midY)
//                                .blendMode(.destinationOut)
//                        )
//                        .ignoresSafeArea()
//                        .compositingGroup()
//                        .background(.clear)
//                }
//                VStack {
//                    Spacer()
//                        .frame(height: buttonRect3.minY - bubbleHeight)
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
        .onTapGesture {
            print("onTapGestureaaa")
            if self.tutorialNum == 5 {
                tutorialNum = 66
                hasSearched = true
            }
            else if showTestuser == true {
                self.tutorialNum = 0 // タップでチュートリアルを終了
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 6) { success in
                            // データベースのアップデートが成功したかどうかをハンドリング
                        }
                    }
                }
            }
//            else if self.tutorialNum == 7 {
//                self.tutorialNum = 8 // タップでチュートリアルを終了
//                viewModel.authenticateUser { isAuthenticated in
//                    if isAuthenticated {
//                        viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 8) { success in
//                            // データベースのアップデートが成功したかどうかをハンドリング
//                        }
//                    }
//                }
//            }else if self.tutorialNum == 0 {
//                self.tutorialNum = 9 // タップでチュートリアルを終了
//                viewModel.authenticateUser { isAuthenticated in
//                    if isAuthenticated {
//                        viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 9) { success in
//                            // データベースのアップデートが成功したかどうかをハンドリング
//                        }
//                    }
//                }
//            }
        }
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

struct RoomCreationPopupView: View {
    @State private var newRoomName = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showAlert = false
    @State private var selectedStatuses: [UserStatus] = []
    @State private var statusInput = ""
    @State private var enteredStatuses: [String] = []
    @State private var showStatusInputView = false
    @State private var buttonRect: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum: Int = 0
    @State private var currentUser: User?

    var body: some View {
        
    NavigationView {
            ZStack{
                VStack(spacing: 20){
                    HStack {
                        Text("グループ名を入力してください")
                            .font(.system(size: 24))
                            .foregroundColor(Color("fontGray"))
                    }
                    Text("20文字以下で入力してください")
                        .font(.system(size: 16))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    ZStack(alignment: .trailing){
                        TextField("グループ名", text: $newRoomName)
                            .onChange(of: newRoomName) { newValue in
                                if newValue.count > 20 {
                                    newRoomName = String(newValue.prefix(20))
                                }
                            }
                            .font(.system(size: 30))
                            .padding(.horizontal,20)
                            .padding(.trailing, newRoomName.isEmpty ? 0 : 40)
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                            })
                        
                        if !newRoomName.isEmpty {
                            Button(action: {
                                self.newRoomName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .font(.system(size: 30))
                            .padding(.trailing, 5)
                        }
                    }
                    Button(action: {
                        viewModel.checkIfGroupNameExists(newRoomName) { exists in
                            if exists {
                                showAlert = true
                            }else{
                                showStatusInputView = true
                            }
                        }
                    }) {
                        // ボタンの背景
                        Text("次へ")
                            .padding(.vertical,10)
                            .padding(.horizontal,25)
                            .font(.headline)
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 25)
                                .fill(newRoomName.isEmpty ? Color.gray : Color("btnColor")))
                        //                .fill(Color("btnColor")))
                        //                        .opacity(goal.isEmpty ? 0.5 : 1.0)
                            .opacity(newRoomName.isEmpty ? 0.5 : 1.0)
                            .padding()
                    }
                    .disabled(newRoomName.isEmpty)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("エラー"),
                            message: Text("グループ名が既に使われています"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    NavigationLink(destination: StatusInputView(newRoomName: $newRoomName, enteredStatuses: $enteredStatuses)
                                   , isActive: $showStatusInputView) {
                        EmptyView() // 非表示のビュー
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
                    Spacer()
                }
            
                if tutorialNum == 2 {
                    GeometryReader { geometry in
                        Color.black.opacity(0.5)
                            .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .frame(width: buttonRect.width, height: buttonRect.height + 10)
                                    .position(x: buttonRect.midX, y: buttonRect.midY)
                                    .blendMode(.destinationOut)
                            )
                            .ignoresSafeArea()
                            .compositingGroup()
                            .background(.clear)
                    }
                    VStack {
                        Spacer()
                            .frame(height: buttonRect.minY - bubbleHeight)
                        VStack(alignment: .trailing, spacing: .zero) {
                        Image("上矢印")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 45.0)
                            Text("作成するグループの名前を入力します。")
                                .font(.system(size: 20.0))
                                .padding(.all, 20.0)
                                .background(Color.white)
                                .cornerRadius(4.0)
                                .padding(.horizontal, 3)
                                .foregroundColor(Color("fontGray"))
                        }
                        .background(GeometryReader { geometry in
                            Path { _ in
                                DispatchQueue.main.async {
                                    self.bubbleHeight = geometry.size.height - 160
                                }
                            }
                        })
                        Spacer()
                    }
                    .ignoresSafeArea()
                    
                }

            }                                   .onPreferenceChange(ViewPositionKey.self) { positions in
                self.buttonRect = positions.first ?? .zero
            }
            .onTapGesture {
                    print("onTapGesturehhh")
                    if self.tutorialNum == 2 {
                        self.tutorialNum = 3 // タップでチュートリアルを終了
                        viewModel.authenticateUser { isAuthenticated in
                            if isAuthenticated {
                                viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 3) { success in
                                    // データベースのアップデートが成功したかどうかをハンドリング
                                }
                            }
                        }
                    }
                }
            .onAppear {
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
    //                        print(currentUser)
                        // 認証成功時の処理
    //                        print("認証に成功しました")
                            if currentUser!.tutorialNum == 2{
                            self.tutorialNum = currentUser!.tutorialNum
                        print("dddd")
                        print(self.tutorialNum)
                            }
                    } else {
                        // 認証失敗時の処理
                    }
                }
            }
//            .padding()
                
                    
        }

            
//        }
    }
}

struct StatusInputView: View {
    @Binding var newRoomName: String
    @Binding var enteredStatuses: [String]
    @State private var status1: String = ""
    @State private var status2: String = ""
    @State private var status3: String = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var isContentView: Bool = false
    @State private var showAlert = false
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum: Int = 0
    @State private var currentUser: User?

    var body: some View {
        ZStack{
            VStack(spacing: 20) {
                HStack {
                    Text("ステータスを入力してください")
                        .font(.system(size: 24))
                        .foregroundColor(Color("fontGray"))
                }
                
                Text("３つステータスを入力してください\n（例）ひま、普通、忙しい")
                    .font(.system(size: 16))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 5)
                
                // 1つ目のステータス入力フォーム
                VStack{
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.green)
                                .frame(width: 15, height: 15)
                            Text("：ステータスを表す色")
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("1つ目のステータス", text: $status1)
                            .onChange(of: status1) { newValue in
                                if newValue.count > 10 {
                                    status1 = String(newValue.prefix(10))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 20))
                            .padding(5)
                            .padding(.horizontal)
                    }
                    // 2つ目のステータス入力フォーム
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.yellow)
                                .frame(width: 15, height: 15)
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("2つ目のステータス", text: $status2)
                            .onChange(of: status2) { newValue in
                                if newValue.count > 10 {
                                    status2 = String(newValue.prefix(10))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 20))
                            .padding(5)
                            .padding(.horizontal)
                    }
                    // 3つ目のステータス入力フォーム
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.red)
                                .frame(width: 15, height: 15)
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("3つ目のステータス", text: $status3)
                            .onChange(of: status3) { newValue in
                                if newValue.count > 10 {
                                    status3 = String(newValue.prefix(10))
                                }
                            }
                            .font(.system(size: 20))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(5)
                            .padding(.horizontal)
                    }
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                })
                Button(action: {
                    // デフォルトのステータスを各テキストフィールドに設定
                    status1 = "ひま"
                    status2 = "普通"
                    status3 = "忙しい"
                }) {
                    Text("サンプルを入力")
                        .padding(.vertical,10)
                        .padding(.horizontal,25)
                        .font(.headline)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(Color("btnColor")))
                        .opacity(1.0)
                        .padding()
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
                })
                .padding(.bottom,-30)
                Button(action: {
                    if status1.isEmpty || status2.isEmpty || status3.isEmpty {
                        showAlert = true
                    } else {
                        enteredStatuses.append(contentsOf: [status1, status2, status3])
                        viewModel.createRoom(withName: newRoomName, statuses: enteredStatuses, userStatuses: enteredStatuses)
                        isContentView = true
                    }
                }) {
                    Text("グループを作成")
                        .padding(.vertical,10)
                        .padding(.horizontal,25)
                        .font(.headline)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(Color("btnColor")))
                        .opacity(1.0)
                        .padding()
                }
                
                NavigationLink("", destination: ContentView().navigationBarBackButtonHidden(true), isActive: $isContentView)
            }
            
            if self.tutorialNum == 3 {
                GeometryReader { geometry in
                    Color.black.opacity(0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .frame(width: buttonRect.width - 20, height: buttonRect.height + 10)
                                .position(x: buttonRect.midX, y: buttonRect.midY)
                                .blendMode(.destinationOut)
                        )
                        .ignoresSafeArea()
                        .compositingGroup()
                        .background(.clear)
                }
                VStack {
                    Spacer()
                        .frame(height: buttonRect.minY - bubbleHeight)
                    VStack(alignment: .trailing, spacing: .zero) {
                        Text("グループ内で使用するステータスを入力します。")
                            .font(.system(size: 20.0))
                            .padding(.all, 10.0)
                            .background(Color.white)
                            .cornerRadius(4.0)
                            .padding(.horizontal, 3)
                            .foregroundColor(Color("fontGray"))
                        Image("下矢印")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 45.0)
                    }
                    .background(GeometryReader { geometry in
                        Path { _ in
                            DispatchQueue.main.async {
                                self.bubbleHeight = geometry.size.height + 10
                            }
                        }
                    })
                    Spacer()
                }
                .ignoresSafeArea()
            }
//            if tutorialNum == 4 {
//                GeometryReader { geometry in
//                    Color.black.opacity(0.5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                .frame(width: buttonRect2.width, height: buttonRect2.height + 0)
//                                .position(x: buttonRect2.midX, y: buttonRect2.midY)
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
//                        Text("「サンプルを入力」をクリックすると\n自動でステータスが入力されます。")
//                            .font(.system(size: 20.0))
//                            .padding(.all, 10.0)
//                            .background(Color.white)
//                            .cornerRadius(4.0)
//                            .padding(.horizontal, 3)
//                            .foregroundColor(Color("fontGray"))
//                        Image("下矢印")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .padding(.trailing, 165.0)
//                    }
//                    .background(GeometryReader { geometry in
//                        Path { _ in
//                            DispatchQueue.main.async {
//                                self.bubbleHeight = geometry.size.height - 220
//                            }
//                        }
//                    })
//                    Spacer()
//                }
//                .ignoresSafeArea()
//            }
        }
        .onTapGesture {
            if self.tutorialNum == 3 {
                self.tutorialNum = 0
                print("currentUserid")
                print(currentUser?.id)
                viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 4) { success in
                }
            } 
//            else if tutorialNum == 4 {
//                tutorialNum = 5
//                viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 5) { success in
//                }
//            }
        }
        .onAppear {
            viewModel.authenticateUser { isAuthenticated in
                if isAuthenticated {
                    currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        print(currentUser)
                    // 認証成功時の処理
//                        print("認証に成功しました")
//                        if self.tutorialNum == 2 {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if currentUser!.tutorialNum == 3{
                    self.tutorialNum = currentUser!.tutorialNum
                    }
//                    }
//                        }
                } else {
                    // 認証失敗時の処理
                }
            }
        }
        .onPreferenceChange(ViewPositionKey.self) { positions in
            self.buttonRect = positions.first ?? .zero
        }
        .onPreferenceChange(ViewPositionKey1.self) { positions in
            self.buttonRect2 = positions.first ?? .zero
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("エラー"),
                message: Text("すべてのステータスを入力してください"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ViewPositionKey: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct ViewPositionKey1: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct ViewPositionKey2: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct RoomListView: View {
    @StateObject var viewModel = UserViewModel()
    @State private var inputUserId: String = ""
    @State private var inputUserName: String = ""
    @State private var isShowingRoomCreationPopup = false
    @State private var isShowingUserSearchView = false
    @State private var newRoomName = ""
    @State private var selectedRoom: Room? = nil
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var roomToDelete: Room?
    @State private var isNavigating = false
    @State private var isPresentingSettingView: Bool = false
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var buttonRect3: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum1: Int = 0
    @State private var tutorialNum2: Int = 0
    @State private var tutorialNum3: Int = 0
    @State private var tutorialNum: Int = 0
    @ObservedObject var authManager: AuthManager
    @State private var currentUser: User?
    
    init() {
        authManager = AuthManager.shared
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Color").edgesIgnoringSafeArea(.all)
                VStack{
                    HStack{
                        Button(action: {
                            isPresentingSettingView = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing)
                        .foregroundColor(.gray)
                        .opacity(0)
                        Spacer()
                        Text("グループ一覧")
                            .font(.system(size: 20))
                        Spacer()
                        Button(action: {
                            isPresentingSettingView = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing)
                        .foregroundColor(Color("fontGray"))
                    }
                    .frame(maxWidth:.infinity,maxHeight:60)
                    .background(Color("btnColor"))
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.sortedActiveRooms) { room in
                                ZStack {
                                    NavigationLink(destination: RoomView(room: room, viewModel: viewModel), isActive: $isNavigating) {
                                        EmptyView()
                                    }
                                    HStack {
                                        Text(room.name)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                    .onTapGesture {
//                                        self.selectedRoom = room
                                        self.isNavigating = true
                                    }
                                    .frame(width: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                }
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(key: ViewPositionKey2.self, value: [geometry.frame(in: .global)])
                                })
                                .padding()
                                .padding(.horizontal, 30)
                            }
                        }
                        .padding(.top)
                    }
                    NavigationLink("", destination: SettingsView().navigationBarBackButtonHidden(true), isActive: $isPresentingSettingView)
                }
                .onReceive(viewModel.$activeRooms) { activeRooms in
                    //                        print("activeRooms updated:", activeRooms)
                }
                .overlay(
                    ZStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack{
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        self.isShowingUserSearchView = true
                                    }, label: {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    }).frame(width: 60, height: 60)
                                    
                                    .background(GeometryReader { geometry in
                                        Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
                                    })
                                        .background(Color("plusRoom"))
                                        .cornerRadius(30.0)
                                        .shadow(radius: 5)
                                        .fullScreenCover(isPresented: $isShowingUserSearchView, content: {
                                            UserSearchView()
                                        })
                                        .padding()
                                    Button(action: {
                                        self.isShowingRoomCreationPopup = true
                                    }, label: {
                                        Image(systemName: "plus")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    })
                                    
                                    .frame(width: 60, height: 60)
                                    .background(GeometryReader { geometry in
                                        Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                                    })
                                    .background(Color("plusUser"))
                                    .cornerRadius(30.0)
                                    .shadow(radius: 5)
                                    .fullScreenCover(isPresented: $isShowingRoomCreationPopup, content: {
                                        RoomCreationPopupView()
                                    })
                                    .padding()
                                    .padding(.trailing)
                                }
                            }
                        }
                    }
                )
                
                .onPreferenceChange(ViewPositionKey.self) { positions in
                    self.buttonRect = positions.first ?? .zero
                }
                
                .onPreferenceChange(ViewPositionKey1.self) { positions in
                    self.buttonRect2 = positions.first ?? .zero
                }
                
                .onPreferenceChange(ViewPositionKey2.self) { positions in
                    self.buttonRect3 = positions.first ?? .zero
                }
                if tutorialNum == 1 {
                    GeometryReader { geometry in
                        Color.black.opacity(0.5)
                            .overlay(
                                Circle()
                                    .frame(width: buttonRect.width, height: buttonRect.height)
                                    .position(x: buttonRect.midX, y: buttonRect.midY)
                                    .blendMode(.destinationOut)
                            )
                            .ignoresSafeArea()
                            .compositingGroup()
                            .background(.clear)
                    }
                    VStack {
                        Spacer()
                            .frame(height: buttonRect.minY - bubbleHeight)
                        VStack(alignment: .trailing, spacing: .zero) {
                            Text("グループを作成しましょう。\nプラスボタンをクリックしてください。")
                                .font(.system(size: 20.0))
                                .padding(.all, 10.0)
                                .background(Color.white)
                                .cornerRadius(4.0)
                                .padding(.horizontal, 3)
                                .foregroundColor(Color("fontGray"))
                            Image("下矢印")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 45.0)
                        }
                        .background(GeometryReader { geometry in
                            Path { _ in
                                DispatchQueue.main.async {
                                    self.bubbleHeight = geometry.size.height + 10
                                }
                            }
                        })
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
                if tutorialNum == 4 {
                    GeometryReader { geometry in
                        Color.black.opacity(0.5)
                            .overlay(
                                Circle()
                                    .frame(width: buttonRect2.width, height: buttonRect2.height)
                                    .position(x: buttonRect2.midX, y: buttonRect2.midY)
                                    .blendMode(.destinationOut)
                            )
                            .ignoresSafeArea()
                            .compositingGroup()
                            .background(.clear)
                    }
                    VStack {
                        Spacer()
                            .frame(height: buttonRect2.minY - bubbleHeight)
                        VStack(alignment: .trailing, spacing: .zero) {
                            Text("作成したグループにユーザーを追加しましょう。\n検索ボタンをクリックしてください。")
                                .font(.system(size: 20.0))
                                .padding(.all, 10.0)
                                .background(Color.white)
                                .cornerRadius(4.0)
                                .padding(.horizontal, 3)
                                .foregroundColor(Color("fontGray"))
                            Image("下矢印")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 138.0)
                        }
                        .background(GeometryReader { geometry in
                            Path { _ in
                                DispatchQueue.main.async {
                                    self.bubbleHeight = geometry.size.height + 10
                                }
                            }
                        })
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
                if tutorialNum == 99 {
                    GeometryReader { geometry in
                        Color.black.opacity(0.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .frame(width: buttonRect3.width, height: buttonRect3.height)
                                    .position(x: buttonRect3.midX, y: buttonRect3.midY)
                                    .blendMode(.destinationOut)
                            )
                            .ignoresSafeArea()
                            .compositingGroup()
                            .background(.clear)
                    }
                    VStack {
                        Spacer()
                            .frame(height: buttonRect3.minY - bubbleHeight)
                        VStack(alignment: .trailing, spacing: .zero) {
                            Image("上矢印")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 138.0)
                            
                            .padding(.top, 190.0)
                            Text("それではグループを確認してみましょう。\nグループ一覧から作成したグループを選択します。")
                                .font(.system(size: 20.0))
                                .padding(.all, 10.0)
                                .background(Color.white)
                                .cornerRadius(4.0)
                                .padding(.horizontal, 3)
                                .foregroundColor(Color("fontGray"))
                        }
                        .background(GeometryReader { geometry in
                            Path { _ in
                                DispatchQueue.main.async {
                                    self.bubbleHeight = geometry.size.height + 10
                                }
                            }
                        })
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
                    
            }
            .onAppear {
                guard let firebaseUser = Auth.auth().currentUser else { return }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                            if currentUser!.tutorialNum == 1 {
//                                self.tutorialNum1 = 1
//                            }
//                            if currentUser!.tutorialNum == 2 {
//                                self.tutorialNum2 = 2
//                            }
//                            if currentUser!.tutorialNum == 3 {
//                                self.tutorialNum3 = 3
//                            }
//                        }
                        print("lllll")
                        if currentUser!.tutorialNum == 1 || currentUser!.tutorialNum == 4 || currentUser!.tutorialNum == 99 {
                            self.tutorialNum = currentUser!.tutorialNum
                        }
                    } else {
                        // 認証失敗時の処理
                    }
                }
            }
            .onTapGesture {
                print("onTapGesturekkk")
                if tutorialNum == 1 {
                    tutorialNum = 2
                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 2) { success in
                    }
                } else if tutorialNum == 4 {
                    tutorialNum = 0
                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 5) { success in
                    }
                } else if tutorialNum == 0 {
                    tutorialNum = 4
                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 4) { success in
                    }
                }
            }
        }
        }
    }



struct roomListView_Previews: PreviewProvider {
    static var previews: some View {
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1",rooms: ["1": true], tutorialNum: 1)
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", rooms: ["1": true], tutorialNum: 1)
        
        let users = [user1, user2]

        // userStatusesのデータを準備
        let userStatuses = ["1": UserStatus.available, "2": UserStatus.busy]

        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", members: ["1": true, "2": true], statuses: ["status_0":"ステータス"], userStatuses: userStatuses)

        RoomListView()
//        RoomCreationPopupView()
//        let enteredStatusesBinding = Binding.constant(["ステータス1", "ステータス2"])
//        
//        StatusInputView(newRoomName: Binding.constant("テストルーム")
//, enteredStatuses: enteredStatusesBinding)
//        UserSearchView()
    }
}

