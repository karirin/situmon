//
//  RoomView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI
import Firebase

struct Room: Identifiable {
    var id: String
    var name: String
    var userIDs: [String]
    var isSwiped: Bool = false
    var isActive: Bool = true
}


struct RoomView: View {
    var room: Room
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var roomToDelete: Room?

    var body: some View {
        VStack {
            HStack{
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                    Text("戻る")
                        .foregroundColor(.black)
                }
                .padding(.leading)
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
            UserListView(viewModel: viewModel, userIds: room.userIDs)
        }
        .alert(isPresented: $showingDeleteAlert) {
           Alert(
               title: Text("退会"),
               message: Text("\(roomToDelete?.name ?? "")を退会しますか？"),
               primaryButton: .destructive(Text("退会")) {
                   if let room = roomToDelete {
                       viewModel.deleteRoom(withID: room.name)
                       self.presentationMode.wrappedValue.dismiss()
                   }
               },
               secondaryButton: .cancel(Text("キャンセル"))
           )
       }
        .navigationBarBackButtonHidden(true)
    }
}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        // Userのインスタンスを作成
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1", status: .available, rooms: ["1": true])
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", status: .busy, rooms: ["1": true])
        
        // ユーザーの配列を作成
        let users = [user1, user2]
        
        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", userIDs: users.map { $0.id })
        
        let viewModel = UserViewModel()
        viewModel.users = users
        return RoomView(room: room, viewModel: viewModel)
    }
}


