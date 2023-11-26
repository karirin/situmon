//
//  TopRoomView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/11/18.
//

import SwiftUI

struct TopRoomView: View {
        var room: Room
        @ObservedObject var viewModel: UserViewModel
        @Environment(\.presentationMode) var presentationMode
        @State private var showingDeleteAlert = false
        @State private var roomToDelete: Room?

        var body: some View {
            VStack {
                HStack{
                    Button(action: {
                        roomToDelete = room
                        showingDeleteAlert = true
                    }) {
                        Text("退会")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .frame(width: 100, height: 44)
                    .transition(.move(edge: .trailing))
                    .opacity(0)
                    Spacer()
                    Text(room.name)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        roomToDelete = room
                        showingDeleteAlert = true
                    }) {
                        Text("退会")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .frame(width: 100, height: 44)
                    .transition(.move(edge: .trailing))
                }
                .frame(maxWidth:.infinity,maxHeight:60)
                .background(Color("btnColor"))
                // 部屋に含まれるユーザーの一覧を表示
                UserListView(viewModel: viewModel, members: room.members, room: room)            }
            .onAppear{
//                print("roomName:\(room.name)")
            }
            .alert(isPresented: $showingDeleteAlert) {
               Alert(
                   title: Text("退会"),
                   message: Text("\(roomToDelete?.name ?? "")を退会しますか？"),
                   primaryButton: .destructive(Text("退会")) {
                       if let room = roomToDelete {
                           viewModel.deleteRoom(withID: room.name)
                       }
                   },
                   secondaryButton: .cancel(Text("キャンセル"))
               )
           }
            .navigationBarBackButtonHidden(true)
        }
    }

struct TopRoomView_Previews: PreviewProvider {
    static var previews: some View {
        // Userのインスタンスを作成
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1", rooms: ["1": true], tutorialNum: 1)
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", rooms: ["1": true], tutorialNum: 1)
        
        // ユーザーの配列を作成
        let users = [user1, user2]
        
        // Roomのインスタンスを作成
        let userStatuses = ["1": UserStatus.available, "2": UserStatus.busy]

        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", members: ["1": true, "2": true], statuses: ["status_0":"ステータスaaa"], userStatuses: userStatuses)
        
        let viewModel = UserViewModel()
        viewModel.users = users
        return TopRoomView(room: room, viewModel: viewModel)
    }
}
