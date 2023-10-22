//
//  roomListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI

struct RoomListView: View {
    @ObservedObject var viewModel = UserViewModel()
    @State private var inputUserId: String = ""
    @State private var inputUserName: String = ""
    @State private var newRoomName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("ユーザー名を入力", text: $inputUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                Button("ユーザー検索") {
                    viewModel.searchUserByName(inputUserName)
                }
                .padding(.bottom, 20)
                
                // 部屋名入力
               TextField("部屋名を入力", text: $newRoomName)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                   .padding(.bottom, 10)

               // 部屋作成ボタン
               Button("部屋を作成") {
                   viewModel.createRoom(withName: newRoomName)
                   newRoomName = ""  // 入力フィールドをクリア
               }
               .padding(.bottom, 20)

                // 検索結果表示
                ForEach(viewModel.searchedUsers) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        Button("部屋1に追加") {
                            viewModel.addUserToRoom(user, to: "部屋1")
                        }
                        Button("部屋2に追加") {
                            viewModel.addUserToRoom(user, to: "部屋2")
                        }
                    }
                    .padding(.bottom, 10)
                }
                ForEach(viewModel.users.filter { user in
                    print("user")
                    print(user)
                    // currentUserIdに一致するユーザーの部屋がtrueのものだけを表示するための条件
                    return (user.id == viewModel.currentUserId) && (user.rooms?.values.contains(true) ?? false)
                }, id: \.id) { user in
                    HStack {
                        ForEach(user.rooms!.keys.filter { roomName in
                            user.rooms![roomName] == true
                        }, id: \.self) { roomName in
                            Text(roomName)
                        }
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct roomListView_Previews: PreviewProvider {
    static var previews: some View {
        RoomListView()
    }
}
