//
//  ContentView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/24.
//

import SwiftUI

struct ContentView: View {
    static let samplePaymentDates: [Date] = [Date()]
    @StateObject var viewModel = UserViewModel()
    @State private var selectedRoom: Room?

    var body: some View {
        VStack {
            TabView {
                ZStack {
                    RoomListView(selectRoom: { room in
                         self.selectedRoom = room
                     })
                }
                .tabItem {
                    Image(systemName: "person.3")
                        .padding()
                    Text("グループ")
                        .padding()
                }
                 if let selectedRoom = selectedRoom {
                     RoomView(room: selectedRoom, viewModel: UserViewModel())
                         .tabItem {
                             Image(systemName: "house") // 任意のアイコン
                             Text("選択された部屋")
                         }
                 }
//                ZStack {
////                    UserListView()
//                }
//                .tabItem {
//                    Image(systemName: "calendar")
//                    Text("カレンダー")
//                }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
            }
        }
        .onAppear {
                    setupInitialSelectedRoom()
                }
    }

    func setupInitialSelectedRoom() {
        // ユーザー認証を試みる
        viewModel.authenticateUser() { isAuthenticated in
            if isAuthenticated {
                // 認証成功後にユーザーの部屋を取得
                viewModel.fetchUserRooms { rooms in
                    // 非同期処理が完了した後に実行されるコード
                    self.viewModel.rooms = rooms ?? []
                    if let firstRoom = rooms?.first {
                        self.selectedRoom = firstRoom
                        print("最初の部屋: \(firstRoom)")
                    }
                }
            } else {
                // 認証に失敗した場合の処理
                print("Authentication failed")
            }
        }
    }



}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
