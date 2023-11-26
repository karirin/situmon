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
    var members: [String: Bool]
    var statuses: [String: String]
    var userStatuses: [String: UserStatus]
    var isSwiped: Bool = false
    var isActive: Bool = true
    
    func statusKey(forLabel label: String) -> String? {
        return statuses.first(where: { $0.value == label })?.key
    }
}

struct RoomView: View {
    var room: Room
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var roomToDelete: Room?

    var body: some View {
        ZStack{
            
            VStack(spacing: 0) {
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
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .opacity(0)
                        Text("退会")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing)
//                    .transition(.move(edge: .trailing))
                }
                .frame(maxWidth:.infinity,maxHeight:60)
                .background(Color("btnColor"))
                
                // 部屋に含まれるユーザーの一覧を表示
                UserListView(viewModel: viewModel, members: room.members, room: room)
            }
            .onAppear{
                print("room:\(room)")
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
}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        // Userのインスタンスを作成
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1", rooms: ["1": true], tutorialNum: 1)
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", rooms: ["1": true], tutorialNum: 1)
        
        // ユーザーの配列を作成
        let users = [user1, user2]
        
        // Roomのインスタンスを作成
        let userStatuses = ["1": UserStatus.available, "2": UserStatus.busy]

        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", members: ["1": true, "2": true], statuses: ["status_0":"あ"], userStatuses: userStatuses)
        
        let viewModel = UserViewModel()
        viewModel.users = users
        return RoomView(room: room, viewModel: viewModel)
    }
}


