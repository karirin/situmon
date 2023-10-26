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
                viewModel.searchUserByName(inputUserName)
                inputUserName = ""
                hasSearched = true
            }) {
                ZStack {
                    Text("ユーザー名を検索")
                }
                .padding(.vertical,10)
                .padding(.horizontal,25)
                .font(.headline)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 25)
                .fill(inputUserName.isEmpty ? Color.gray : Color("btnColor")))
//                .fill(Color("btnColor")))
//                        .opacity(goal.isEmpty ? 0.5 : 1.0)
                .opacity(0.5)
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
                            Text("部屋を選択してください")
                                .font(.system(size: 20))
                            Picker("", selection: $selectedRoom) {
                                ForEach(getUserRooms(), id: \.self) { roomName in
                                    Text(roomName).tag(roomName)
                                        .font(.system(size: 40))
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
                        Button(action: {
                            let userRooms = getUserRooms()
                            if !selectedRoom.isEmpty {
                                print("選択された部屋: \(selectedRoom)")
                                print("ユーザーの部屋: \(user.rooms)")
                                if user.rooms[selectedRoom] == true {
                                    // 既にグループにユーザーが存在する場合
                                    alertMessage = "このユーザーはすでに\(selectedRoom)に入っています"
                                    showAlert = true
                                } else {
                                    viewModel.addUserToRoom(user, to: selectedRoom)
                                    alertMessage = "ユーザーを\(selectedRoom)に追加しました！"
                                    showAlert = true
                                    selectedRoom = "" // 部屋を追加した後は選択をクリア
                                }
                            }
                        }) {
                            Text("ユーザーをグループに追加")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                                .font(.headline)
                                .foregroundColor(.white)
                                .background(RoundedRectangle(cornerRadius: 25)
                                                .fill(Color("btnColor")))
                                .opacity(0.5)
                                .padding()
                        }
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
        if let currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId }) {
            let rooms = currentUser.rooms ?? [:]  // nilの場合は空の辞書を返す
            return rooms.filter { $0.value == true }.keys.sorted()
        }
        return []
    }
}

struct RoomCreationPopupView: View {
    @State private var newRoomName = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

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
//                        .frame(width:.infinity)
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
                viewModel.createRoom(withName: newRoomName)
                newRoomName = ""
                self.presentationMode.wrappedValue.dismiss()
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
                .opacity(0.5)
                .padding()
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

    var body: some View {
        NavigationView{
        ZStack{
            Color("Color")
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading) {
                        List(viewModel.activeRooms) { room in
                            VStack(alignment: .leading) {
                                Text("Room Name: \(room.name)")
                                Text("Room ID: \(room.id)")
                            }
                        }
                    }
                }
                    .padding()
                    .onAppear {
                        viewModel.loadData()
                    }
                }
        

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



struct roomListView_Previews: PreviewProvider {
    static var previews: some View {
        RoomListView()
//        UserSearchView()
//        RoomCreationPopupView()
    }
}
