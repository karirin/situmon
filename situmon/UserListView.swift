//
//  UserListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/20.
//

import SwiftUI

enum UserStatus: String {
    case available = "質問して大丈夫です"
    case aBitBusy = "少し忙しい"
    case busy = "いま忙しい"
}

extension UserStatus {
    var color: Color {
        switch self {
        case .available:
            return Color.green
        case .aBitBusy:
            return Color.yellow
        case .busy:
            return Color.red
        }
    }
}

struct UserView: View {
    var user: User
    @ObservedObject var viewModel = UserViewModel()
    @State private var selectedStatus: UserStatus = .available
    
    var body: some View {
        VStack{
            HStack {
                // ステータスに応じた色の丸表示
                Circle()
                    .fill(user.status.color)
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 10)
                
                // アイコン表示
                VStack{
                    Image(user.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    Text(user.name)
                }.padding(.trailing, 10)
                
                // ステータス表示
                Text(user.status.rawValue)
                    .font(.system(size:22))
                //                .padding(.leading, 10)
                Spacer()
            }
            HStack{
                Spacer()
                if let currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId }), currentUser.id == user.id {
                    UserStatusUpdateView(selectedStatus: $selectedStatus) { newStatus in
                        if let userId = viewModel.currentUserId {
                            viewModel.updateStatus(for: userId, to: newStatus)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct UserStatusUpdateView: View {
    @Binding var selectedStatus: UserStatus
    let updateAction: (UserStatus) -> Void
    
    var body: some View {
        HStack(spacing: -20){
            Text("ステータス：")
                .foregroundColor(Color.gray)
            Picker("ステータス:", selection: $selectedStatus) {
                Text("質問して大丈夫です").tag(UserStatus.available)
                Text("少し忙しい").tag(UserStatus.aBitBusy)
                Text("いま忙しい").tag(UserStatus.busy)
            }
            .accentColor(Color.gray)
            .onChange(of: selectedStatus) { newStatus in
                // ステータスが変更されたときに updateAction を呼び出します
                updateAction(newStatus)
            }
        }
    }
}


struct UserListView: View {
    @ObservedObject var viewModel = UserViewModel()
    @State private var selectedStatus: UserStatus = .available
    var userIds: [String]

    var body: some View {
        ZStack {
            Color("Color") // ここで背景色を指定
                .edgesIgnoringSafeArea(.all)
            VStack{
                
                ScrollView{
                    VStack {
                        if let currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId }) {
                            UserView(user: currentUser)
                                .padding(.bottom, 30) // 余白を追加して他のユーザーと区別
                        }

                        if viewModel.users.isEmpty {
                            Text("Loading...")
                        } else {
                            ForEach(viewModel.users.filter { userIds.contains($0.id) }) { user in
                                     if user.id != viewModel.currentUserId {
                                         UserView(user: user)
                                     }
                                 }
                        }
                        
                    }.padding()
                }
                .onAppear(perform: {
                    viewModel.fetchData { success in
                        if success {
                            print("データの読み込みが成功しました！")
                        } else {
                            print("データの読み込みに失敗しました。")
                        }
                    }
                })
            }
        }
    }
}


struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用のユーザーIDの配列を作成
        let userIds = ["1", "2"]
        
        // UserListViewにプレビュー用のデータを渡してプレビュー
        UserListView(userIds: userIds)
    }
}

