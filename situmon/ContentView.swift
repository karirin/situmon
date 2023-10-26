//
//  ContentView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/24.
//

import SwiftUI

struct ContentView: View {
    static let samplePaymentDates: [Date] = [Date()]

    var body: some View {
        VStack {
            TabView {
                ZStack {
                    RoomListView()
                }
                .tabItem {
                    Image(systemName: "house")
                        .padding()
                    Text("ホーム")
                        .padding()
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
