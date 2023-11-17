//
//  roomListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI

struct UserSearchView: View {
    @State private var inputUserName = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var selectedRoom: String = ""
    @State private var alertMessage: String = ""
    @State private var hasSearched = false
    @State private var showAlert = false
    
    func addUserToRoom(_ user: User, to roomName: String) {
        // 部屋を探す
        if let roomIndex = viewModel.activeRooms.firstIndex(where: { $0.name == roomName }) {
            // ユーザIDが部屋のユーザIDリストに含まれていない場合、追加する
            if !viewModel.activeRooms[roomIndex].userIDs.contains(user.id) {
                viewModel.activeRooms[roomIndex].userIDs.append(user.id)
                alertMessage = "ユーザーを\(roomName)に追加しました！"
            } else {
                // 既にグループにユーザーが存在する場合
                alertMessage = "このユーザーはすでに\(roomName)に入っています"
            }
            showAlert = true
            selectedRoom = "" // 部屋を追加した後は選択をクリア
        } else {
            // 部屋が見つからない場合のエラーメッセージ
            alertMessage = "\(roomName)は存在しません"
            showAlert = true
        }
    }

    // ユーザーを部屋に追加するボタンのアクション
    var addUserToRoomAction: () -> Void {
        print("addUserToRoomAction1")
        return {
            guard let user = viewModel.searchedUsers.first else { print("return")
                return }
            print("addUserToRoomAction2")
            viewModel.addUserToRoom(user, to: selectedRoom)
            addUserToRoom(user, to: selectedRoom)
        }
    }
    
    var body: some View {
        VStack {
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
                .padding(.leading)
            }
            .padding(.bottom)
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
                print("Searching for user with name: \(inputUserName)")
                viewModel.searchUserByName(inputUserName)
                inputUserName = ""
                hasSearched = true
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
            Spacer()
            if hasSearched && viewModel.searchedUsers.isEmpty {
                Text("ユーザーが見つかりませんでした")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            } else {
                ForEach(viewModel.searchedUsers) { user in
                    VStack {
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
                                    } else {
                                        // 認証失敗時の処理
                                    }
                                }
                                let rooms = getUserRooms()
                                if !rooms.isEmpty {
                                    selectedRoom = rooms[0]
                                    print("selectedRoom:\(selectedRoom)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle()) // メニュー形式のピッカーにする
                            .accentColor(Color("fontGray"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(.black.opacity(3), lineWidth: 1)
                            )
                        }
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
//                        .disabled(selectedRoom.isEmpty)
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
                
            
            Spacer()
            Spacer()
        }
        .onAppear{
            hasSearched = false
        }
        Spacer()
    }
    func getUserRooms() -> [String] {
        // 現在のユーザIDを確認
        guard let currentUserId = viewModel.currentUserId else {  print("return"); return [] }
        print("viewModel.activeRooms")
        print(viewModel.activeRooms)
        // アクティブな部屋をフィルタリングして、部屋の名前の配列を返す
        return viewModel.activeRooms.filter { room in
            return room.userIDs.contains(currentUserId)
        }.map { $0.name }.sorted()
    }
}

struct RoomCreationPopupView: View {
    @State private var newRoomName = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20){
//            VStack(spacing: 20) {
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
                    .padding(.leading)
                }
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
                        .padding(.trailing, newRoomName.isEmpty ? 0 : 40)
                    
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
                        viewModel.createRoom(withName: newRoomName)
                        newRoomName = ""
                        print("showAlert2")
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                    // ボタンの背景
            Text("グループを作成")
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
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text("グループ名が既に使われています"),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            Spacer()
            }

            .padding()
            
//        }
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
    var selectRoom: (Room) -> Void
    @State private var isNavigating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Color").edgesIgnoringSafeArea(.all)
                VStack{
                    HStack{
                        Spacer()
                        Text("グループ一覧")
                            .font(.system(size: 20))
                        Spacer()
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
                                            self.selectedRoom = room
                                            self.isNavigating = true
                                        }
                                        .frame(width: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                    }
                                    .padding()
                                    .padding(.horizontal, 30)
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .onAppear {
                        viewModel.authenticateUser { isAuthenticated in
                            if isAuthenticated {
                                // 認証成功時の処理
                                print("認証に成功しました")
                            } else {
                                // 認証失敗時の処理
                            }
                        }
                    }
                    .onReceive(viewModel.$activeRooms) { activeRooms in
                        print("activeRooms updated:", activeRooms)
                    }
                }
                //               .navigationTitle("Rooms")
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
                                    }).frame(width: 60, height: 60)
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
            }
        }
    }



struct roomListView_Previews: PreviewProvider {
    
    static var previews: some View {
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1", status: .available, rooms: ["1": true])
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", status: .busy, rooms: ["1": true])
        
        // ユーザーの配列を作成
        let users = [user1, user2]
        
        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", members: ["2": true], userIDs: users.map { $0.id })
        RoomListView(selectRoom: { room in
//            self.selectedRoom = room
        })
//        UserSearchView()
//        RoomCreationPopupView()
    }
}
