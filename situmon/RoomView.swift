//
//  RoomView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI

struct Room: Identifiable {
    var id: UUID
    var name: String
    var userIDs: [String]  // ユーザーIDの配列
}


struct RoomView: View {
    var room: Room
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(room.name)
                .font(.headline)
                .padding(.bottom, 10)
            
            UserListView(viewModel: viewModel)
        }
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
        let room = Room(id: UUID(), name: "部屋1", userIDs: users.map { $0.id })
        
        let viewModel = UserViewModel()
        viewModel.users = users
        return RoomView(room: room, viewModel: viewModel)
    }
}


