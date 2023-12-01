//
//  UserListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/20.
//

import SwiftUI
import Firebase

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
    var room: Room
    @State private var currentUser: User?
    @State private var availableStatuses: [String] = []
    @State private var selectedStatus: String = ""
    
    var body: some View {
        VStack{
            HStack {
                // ステータスに応じた色の丸表示
                Circle()
                    .fill(StatusColorManager.shared.color(forUserId: user.id))
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 5)
                    .onChange(of: selectedStatus) { newValue in
                        if let statusKey = room.statusKey(forLabel: newValue) {
                            StatusColorManager.shared.updateColor(forUserId: user.id, withStatus: statusKey)
                        }
                    }
                
                // アイコン表示
                VStack{
                    Image(user.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    Text(user.name)
                }.padding(.trailing, 5)
                
                // ステータス表示
                if let currentUser = currentUser, currentUser.id == user.id {
                    UserStatusUpdateView(
                        selectedStatus: $selectedStatus,
                        statuses: availableStatuses,
                        updateAction: { newStatus in
                            if currentUser.id == user.id {
                                updateUserStatus(in: room.name, userId: user.id, newStatus: newStatus)
//                                StatusColorManager.shared.updateColor(forUserId: user.id, withStatus: newStatus)
                            }
                        }
                    )
                }else{
                    Text(StatusColorManager.shared.userStatus(forUserId: user.id))
                        .font(.system(size:18))
                        .padding(.leading, 10)
                }
                Spacer()
            }
            .onAppear{
                fetchCurrentUserStatus(userId: user.id, in: room.name) { status in
                    if let status = status {
                        selectedStatus = status
                    }
                }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        // 認証成功時の処理
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        print("currentUser userview")
//                        print(currentUser)
                    } else {
                        // 認証失敗時の処理
                    }
                }
                fetchAvailableStatuses(for: room.name) { statuses in
                    availableStatuses = statuses
                }
                fetchRoomsData()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    func fetchCurrentUserStatus(userId: String, in roomName: String, completion: @escaping (String?) -> Void) {
        let userStatusRef = Database.database().reference(withPath: "rooms/\(roomName)/Userstatus/\(userId)")
        userStatusRef.observeSingleEvent(of: .value, with: { snapshot in
            let status = snapshot.value as? String
            completion(status)
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }
    
    func fetchRoomsData() {
        let roomsRef = Database.database().reference(withPath: "rooms")

        roomsRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let roomsValue = snapshot.value as? [String: Any] else {
                print("No rooms data found")
                return
            }
            var Statuses: [String: String] = [:] // ユーザーIDをキーとするステータスの辞書
            var userStatuses: [String: String] = [:]

            for (_, roomData) in roomsValue {
                if let roomInfo = roomData as? [String: Any],
                   let userStatus = roomInfo["Userstatus"] as? [String: String],
                   let statuses = roomInfo["statuses"] as? [String: String] {
                    // 各ユーザーのステータスを特定
                    for (userId, statusValue) in userStatus {
                        for (statusKey, statusLabel) in statuses {
                            if statusValue == statusLabel {
                                Statuses[userId] = statusKey
                            }
                        }
                    }
                    
                    for (userId, statusValue) in userStatus {
                        userStatuses[userId] = statusValue
                    }
                }
            }

            // ここでStatusColorManagerのマッピングを更新する
            StatusColorManager.shared.updateStatusColors(with: Statuses)
            StatusColorManager.shared.updateuserStatus(with: userStatuses)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    func fetchAvailableStatuses(for roomName: String, completion: @escaping ([String]) -> Void) {
        let statusesRef = Database.database().reference(withPath: "rooms/\(roomName)/statuses")
        statusesRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let statusesDict = snapshot.value as? [String: String] else {
                print("Statuses not found")
                completion([])
                return
            }

            let statuses = Array(statusesDict.values)
            completion(statuses)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    func updateUserStatus(in roomName: String, userId: String, newStatus: String) {
        let userStatusRef = Database.database().reference(withPath: "rooms/\(roomName)/Userstatus/\(userId)")
        userStatusRef.setValue(newStatus) { error, _ in
            if let error = error {
                print("Error updating user status: \(error.localizedDescription)")
            } else {
                print("User status updated successfully")
            }
        }
    }
}

class StatusColorManager {
    static let shared = StatusColorManager()
    private var userStatusColorMap: [String: Color] = [:]
    private var userStatusTextMap: [String: String] = [:]
    
    func updateColor(forUserId userId: String, withStatus status: String) {
        print("status:\(status)")
        switch status {
        case "status_0":
            userStatusColorMap[userId] = Color.green
        case "status_1":
            userStatusColorMap[userId] = Color.yellow
        case "status_2":
            userStatusColorMap[userId] = Color.red
        default:
            userStatusColorMap[userId] = Color.gray
        }
    }

    func updateStatusColors(with userStatuses: [String: String]) {
        for (userId, statusKey) in userStatuses {
            switch statusKey {
            case "status_0":
                userStatusColorMap[userId] = Color.green
            case "status_1":
                userStatusColorMap[userId] = Color.yellow
            case "status_2":
                userStatusColorMap[userId] = Color.red
            default:
                userStatusColorMap[userId] = Color.gray
            }
        }
    }
    
    func updateuserStatus(with userStatuses: [String: String]) {
        for (userId, statusKey) in userStatuses {
            userStatusTextMap[userId] = statusKey
        }
    }

    func color(forUserId userId: String) -> Color {
        return userStatusColorMap[userId] ?? Color.gray
    }
    
    func userStatus(forUserId userId: String) -> String {
        return userStatusTextMap[userId] ?? "ひま"
    }
}


struct UserStatusUpdateView: View {
    @Binding var selectedStatus: String
    var statuses: [String]
    var updateAction: (String) -> Void

    var body: some View {
        let sortedStatuses = sortStatuses(statuses)
        Picker("ステータス:", selection: $selectedStatus) {
            ForEach(sortedStatuses, id: \.self) { status in
                Text(status).tag(status)
            }
        }
        .onChange(of: selectedStatus) { newStatus in
            updateAction(newStatus)
        }
    }
    
    func sortStatuses(_ statuses: [String]) -> [String] {
        let sortedStatuses = statuses.sorted { a, b in
            // "status_" に続く数字部分で比較してソート
            let aValue = Int(a.replacingOccurrences(of: "status_", with: "")) ?? 0
            let bValue = Int(b.replacingOccurrences(of: "status_", with: "")) ?? 0
            return aValue < bValue
        }
        return sortedStatuses
    }

}


struct UserListView: View {
    @ObservedObject var viewModel = UserViewModel()
    var members: [String : Bool]
    var room: Room
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var buttonRect3: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum1: Int = 0
    @State private var tutorialNum2: Int = 0
    @State private var tutorialNum3: Int = 0
    
    class StatusColorManager {
        static let shared = StatusColorManager()
        private var statusColorMap: [String: Color] = [:]

        private init() {}

        func setColor(forStatus status: String, color: Color) {
            statusColorMap[status] = color
        }

        func color(forStatus status: String) -> Color {
            return statusColorMap[status] ?? Color.gray // 未知のステータスの場合は灰色を返す
        }
    }

    var body: some View {
        ZStack {
            Color("Color") // ここで背景色を指定
                .edgesIgnoringSafeArea(.all)
            VStack{
                ScrollView{
                    VStack {
                        if let currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId }) {
                            
                                UserView(user: currentUser, room: room)
                                .padding(.bottom,30)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                        })
                            }

                        if viewModel.users.isEmpty {
                            Text("Loading...")
                        } else {
                        ForEach(viewModel.users.filter { user in members.contains { $0.key == user.id } }) { user in
                                 if user.id != viewModel.currentUserId {
                                     UserView(user: user, room: room)
                                         .background(GeometryReader { geometry in
                                             Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
                                         })
                                 }
                             }
                        }
                        
                    }
                    .padding()
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
            .onPreferenceChange(ViewPositionKey.self) { positions in
                self.buttonRect = positions.first ?? .zero
            }
            .onPreferenceChange(ViewPositionKey1.self) { positions in
                self.buttonRect2 = positions.first ?? .zero
            }
            if tutorialNum1 == 1 {
               GeometryReader { geometry in
                   Color.black.opacity(0.5)
                       .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                               .frame(width: buttonRect.width, height: buttonRect.height)
                               .position(x: buttonRect.midX, y: buttonRect.midY - 100)
                               .blendMode(.destinationOut)
                       )
                       .ignoresSafeArea()
                       .compositingGroup()
                       .background(.clear)
               }
               VStack {
                   Spacer()
                       .frame(height: buttonRect.minY - bubbleHeight)
                   VStack(alignment: .trailing, spacing: .zero) {
                       Image("上矢印")
                       .resizable()
                       .frame(width: 20, height: 20)
                       .padding(.trailing, 138.0)
                       Text("自分のユーザーが一番上に表示されています。\nプルダウンからステータスを自由に変更することができます。")
                           .font(.system(size: 20.0))
                           .padding(.all, 10.0)
                           .background(Color.white)
                           .cornerRadius(4.0)
                           .padding(.horizontal, 3)
                           .foregroundColor(Color("fontGray"))
                   }
                   .background(GeometryReader { geometry in
                       Path { _ in
                           DispatchQueue.main.async {
                               self.bubbleHeight = geometry.size.height - 110
                           }
                       }
                   })
                   Spacer()
               }
               .ignoresSafeArea()
           }
            if tutorialNum2 == 1 {
               GeometryReader { geometry in
                   Color.black.opacity(0.5)
                       .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                               .frame(width: buttonRect2.width, height: buttonRect2.height)
                               .position(x: buttonRect2.midX, y: buttonRect2.midY - 100)
                               .blendMode(.destinationOut)
                       )
                       .ignoresSafeArea()
                       .compositingGroup()
                       .background(.clear)
               }
               VStack {
                   Spacer()
                       .frame(height: buttonRect2.minY - bubbleHeight)
                   VStack(alignment: .trailing, spacing: .zero) {
                       Image("上矢印")
                       .resizable()
                       .frame(width: 20, height: 20)
                       .padding(.trailing, 138.0)
                       Text("その他、このグループに参加しているユーザーを一覧表示しています。")
                           .font(.system(size: 20.0))
                           .padding(.all, 10.0)
                           .background(Color.white)
                           .cornerRadius(4.0)
                           .padding(.horizontal, 3)
                           .foregroundColor(Color("fontGray"))
                   }
                   .background(GeometryReader { geometry in
                       Path { _ in
                           DispatchQueue.main.async {
                               self.bubbleHeight = geometry.size.height - 100
                           }
                       }
                   })
                   Spacer()
               }
               .ignoresSafeArea()
           }
        }
    }
}


struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用のユーザーIDの配列を作成
        let members = ["1": true]
        let userStatuses = ["1": UserStatus.available, "2": UserStatus.busy]
        let room = Room(id: "", name: "部屋1", members: ["1": true, "2": true], statuses: ["status_0":"ステータスあああ"], userStatuses: userStatuses)
        
        // UserListViewにプレビュー用のデータを渡してプレビュー
        UserListView(members: members, room: room)
    }
}

