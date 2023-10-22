//
//  roomListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI

struct UserSearchView: View {
    @Binding var inputUserName: String
    var onSearch: () -> Void
    
    var body: some View {
        VStack {
            TextField("ユーザー名を入力", text: $inputUserName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)

            Button("ユーザー検索", action: onSearch)
                .padding(.bottom, 20)
        }
    }
}

struct RoomCreationView: View {
    @Binding var newRoomName: String
    var onCreate: () -> Void
    
    var body: some View {
        VStack {
            TextField("部屋名を入力", text: $newRoomName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)

            Button("部屋を作成", action: onCreate)
                .padding(.bottom, 20)
        }
    }
}

struct RoomListView: View {
    @ObservedObject var viewModel = UserViewModel()
    @State private var inputUserId: String = ""
    @State private var inputUserName: String = ""
    @State private var newRoomName: String = ""
    @State private var selectedRoom: Room? = nil
    @State private var isLoading = true

    var body: some View {
        NavigationView{
//            if isLoading {
//                            Text("ローディング中...")
//            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        UserSearchView(inputUserName: $inputUserName, onSearch: {
                            viewModel.searchUserByName(inputUserName)
                        })
                        
                        RoomCreationView(newRoomName: $newRoomName, onCreate: {
                            viewModel.createRoom(withName: newRoomName)
                            newRoomName = ""
                        })
                        
                        userSearchResults
                        
                        userRooms
                    }
                    .padding()
                }
            }
        }
//        .onAppear {
//            // データがロードされるのを待つ
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // 仮に3秒待つ
//                self.isLoading = false
//            }
//        }
//    }
//}
    
    var userSearchResults: some View {
        ForEach(viewModel.searchedUsers) { user in
            HStack {
                Text(user.name)
                Spacer()
                
                Menu {
                    ForEach(getUserRooms(), id: \.self) { roomName in
                        Button(roomName) {
                            viewModel.addUserToRoom(user, to: roomName)
                        }
                    }
                } label: {
                    Text("部屋に追加")
                }
            }
            .padding(.bottom, 10)
        }
    }
    
    var userRooms: some View {
        ForEach(viewModel.users.filter { user in
            (user.id == viewModel.currentUserId) && (user.rooms?.values.contains(true) ?? false)
        }, id: \.id) { user in
            roomLinks(for: user)
                .onAppear {
//                    print(user)
                }
        }
    }
    
    func roomLinks(for user: User) -> some View {
        HStack {
            ForEach(user.rooms!.keys.filter { roomName in
                user.rooms![roomName] == true
            }, id: \.self) { roomName in
                roomLink(roomName)
                    .onAppear {
                        print(roomName)
                    }
            }
            Spacer()
        }
    }
    
    func roomLink(_ roomName: String) -> some View {
        print("ViewModel Rooms: \(viewModel.rooms)")
        print("Searching for Room Name: \(roomName)")
        if let room = viewModel.rooms.first(where: { $0.name == roomName }) {
            print("Room Found: \(room)")
            return AnyView(NavigationLink(destination: RoomView(room: room, viewModel: viewModel)) {
                Text(roomName)
            })
        } else {
//            print("Room Not Found")
            return AnyView(Text(roomName)) // またはエラーメッセージ等
        }
    }
    
    func getUserRooms() -> [String] {
        if let currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId }),
           let rooms = currentUser.rooms {
            return rooms.filter { $0.value == true }.keys.sorted()
        }
        return []
    }
}


struct roomListView_Previews: PreviewProvider {
    static var previews: some View {
        RoomListView()
    }
}
