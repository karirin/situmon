//
//  ContentView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/24.
//

import SwiftUI

struct ContentView: View {
    static let samplePaymentDates: [Date] = [Date()]
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
