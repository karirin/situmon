//
//  roomListView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/10/21.
//

import SwiftUI
import Firebase

struct ViewPositionKey: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct ViewPositionKey1: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct ViewPositionKey2: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct RoomListView: View {
    @StateObject var viewModel = UserViewModel()
    @State private var inputUserId: String = ""
    @State private var inputUserName: String = ""
    @State private var isShowingRoomCreationPopup = false
    @State private var isShowingUserSearchView = false
    @State private var newRoomName = ""
    @State private var selectedRoom: Room? = nil
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var roomToDelete: Room?
    @State private var isNavigating = false
    @State private var isPresentingSettingView: Bool = false
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var buttonRect3: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum1: Int = 0
    @State private var tutorialNum2: Int = 0
    @State private var tutorialNum3: Int = 0
    @State private var tutorialNum: Int = 0
    @ObservedObject var authManager: AuthManager
    @State private var currentUser: User?
    @State private var room: Room?
    
    init() {
        authManager = AuthManager.shared
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Color").edgesIgnoringSafeArea(.all)
                VStack{
                    HStack{
                        Button(action: {
                            isPresentingSettingView = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing)
                        .foregroundColor(.gray)
                        .opacity(0)
                        Spacer()
                        Text("グループ一覧")
                            .font(.system(size: 20))
                        Spacer()
                        Button(action: {
                            isPresentingSettingView = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing)
                        .foregroundColor(Color("fontGray"))
                    }
                    .frame(maxWidth:.infinity,maxHeight:60)
                    .background(Color("btnColor"))
                    ScrollView {
                        VStack(alignment: .leading) {
                            if let safeRoom = self.room {
                                NavigationLink(destination: RoomView(room: safeRoom, viewModel: viewModel), isActive: $isNavigating) {
                                    EmptyView()
                                }
                            }
                            ForEach(viewModel.sortedActiveRooms) { room in
                                ZStack {
                                    Button(action: {
                                        self.room = room
                                        self.isNavigating = true
                                    }) {
                                        HStack {
                                            Text(room.name)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                        }
                                        .frame(width: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                        .foregroundColor(Color("fontGray"))
                                    }
                                }
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(key: ViewPositionKey2.self, value: [geometry.frame(in: .global)])
                                })
                                .padding()
                                .padding(.horizontal, 30)
                            }
                        }
                        .padding(.top)
                    }
                    NavigationLink("", destination: SettingsView().navigationBarBackButtonHidden(true), isActive: $isPresentingSettingView)
                }
                .overlay(
                    ZStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack{
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        self.isShowingUserSearchView = true
                                    }, label: {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    }).frame(width: 60, height: 60)
                                    
//                                    .background(GeometryReader { geometry in
//                                        Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
//                                    })
                                        .background(Color("plusRoom"))
                                        .cornerRadius(30.0)
                                        .shadow(radius: 5)
                                        .fullScreenCover(isPresented: $isShowingUserSearchView, content: {
                                            UserSearchView()
                                        })
                                        .padding()
                                    Button(action: {
                                        self.isShowingRoomCreationPopup = true
                                    }, label: {
                                        Image(systemName: "plus")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    })
                                    
                                    .frame(width: 60, height: 60)
                                    .background(GeometryReader { geometry in
                                        Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                                    })
                                    .background(Color("plusUser"))
                                    .cornerRadius(30.0)
                                    .shadow(radius: 5)
                                    .fullScreenCover(isPresented: $isShowingRoomCreationPopup, content: {
                                        RoomCreationPopupView()
                                    })
                                    .padding()
                                    .padding(.trailing)
                                }
                            }
                        }
                    }
                )
                
    //                .onPreferenceChange(ViewPositionKey.self) { positions in
    //                    self.buttonRect = positions.first ?? .zero
    //                }
    //
    //                .onPreferenceChange(ViewPositionKey1.self) { positions in
    //                    self.buttonRect2 = positions.first ?? .zero
    //                }
    //
    //                .onPreferenceChange(ViewPositionKey2.self) { positions in
    //                    self.buttonRect3 = positions.first ?? .zero
    //                }
//                if tutorialNum == 1 {
//                    GeometryReader { geometry in
//                        Color.black.opacity(0.5)
//                            .overlay(
//                                Circle()
//                                    .frame(width: buttonRect.width, height: buttonRect.height)
//                                    .position(x: buttonRect.midX, y: buttonRect.midY)
//                                    .blendMode(.destinationOut)
//                            )
//                            .ignoresSafeArea()
//                            .compositingGroup()
//                            .background(.clear)
//                    }
//                    VStack {
//                        Spacer()
//                            .frame(height: buttonRect.minY - bubbleHeight)
//                        VStack(alignment: .trailing, spacing: .zero) {
//                            Text("グループを作成しましょう。\nプラスボタンをクリックしてください。")
//                                .font(.system(size: 20.0))
//                                .padding(.all, 10.0)
//                                .background(Color.white)
//                                .cornerRadius(4.0)
//                                .padding(.horizontal, 3)
//                                .foregroundColor(Color("fontGray"))
//                            Image("下矢印")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                                .padding(.trailing, 45.0)
//                        }
//                        .background(GeometryReader { geometry in
//                            Path { _ in
//                                DispatchQueue.main.async {
//                                    self.bubbleHeight = geometry.size.height + 10
//                                }
//                            }
//                        })
//                        Spacer()
//                    }
//                    .ignoresSafeArea()
//                }
//                if tutorialNum == 4 {
//                    GeometryReader { geometry in
//                        Color.black.opacity(0.5)
//                            .overlay(
//                                Circle()
//                                    .frame(width: buttonRect2.width, height: buttonRect2.height)
//                                    .position(x: buttonRect2.midX, y: buttonRect2.midY)
//                                    .blendMode(.destinationOut)
//                            )
//                            .ignoresSafeArea()
//                            .compositingGroup()
//                            .background(.clear)
//                    }
//                    VStack {
//                        Spacer()
//                            .frame(height: buttonRect2.minY - bubbleHeight)
//                        VStack(alignment: .trailing, spacing: .zero) {
//                            Text("作成したグループにユーザーを追加しましょう。\n検索ボタンをクリックしてください。")
//                                .font(.system(size: 20.0))
//                                .padding(.all, 10.0)
//                                .background(Color.white)
//                                .cornerRadius(4.0)
//                                .padding(.horizontal, 3)
//                                .foregroundColor(Color("fontGray"))
//                            Image("下矢印")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                                .padding(.trailing, 138.0)
//                        }
//                        .background(GeometryReader { geometry in
//                            Path { _ in
//                                DispatchQueue.main.async {
//                                    self.bubbleHeight = geometry.size.height + 10
//                                }
//                            }
//                        })
//                        Spacer()
//                    }
//                    .ignoresSafeArea()
//                }
//                if tutorialNum == 99 {
//                    GeometryReader { geometry in
//                        Color.black.opacity(0.5)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                                    .frame(width: buttonRect3.width, height: buttonRect3.height)
//                                    .position(x: buttonRect3.midX, y: buttonRect3.midY)
//                                    .blendMode(.destinationOut)
//                            )
//                            .ignoresSafeArea()
//                            .compositingGroup()
//                            .background(.clear)
//                    }
//                    VStack {
//                        Spacer()
//                            .frame(height: buttonRect3.minY - bubbleHeight)
//                        VStack(alignment: .trailing, spacing: .zero) {
//                            Image("上矢印")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                                .padding(.trailing, 138.0)
//                            
//                            .padding(.top, 190.0)
//                            Text("それではグループを確認してみましょう。\nグループ一覧から作成したグループを選択します。")
//                                .font(.system(size: 20.0))
//                                .padding(.all, 10.0)
//                                .background(Color.white)
//                                .cornerRadius(4.0)
//                                .padding(.horizontal, 3)
//                                .foregroundColor(Color("fontGray"))
//                        }
//                        .background(GeometryReader { geometry in
//                            Path { _ in
//                                DispatchQueue.main.async {
//                                    self.bubbleHeight = geometry.size.height + 10
//                                }
//                            }
//                        })
//                        Spacer()
//                    }
//                    .ignoresSafeArea()
//                }
//                    
            }
            .onAppear {
                guard let firebaseUser = Auth.auth().currentUser else { return }
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
//                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                        if currentUser!.tutorialNum == 1 || currentUser!.tutorialNum == 4 || currentUser!.tutorialNum == 99 {
//                            self.tutorialNum = currentUser!.tutorialNum
//                        }
                    } else {
                        // 認証失敗時の処理
                    }
                }
            }
//            .onTapGesture {
//                print("onTapGesturekkk")
//                if tutorialNum == 1 {
//                    tutorialNum = 2
//                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 2) { success in
//                    }
//                } else if tutorialNum == 4 {
//                    tutorialNum = 0
//                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 5) { success in
//                    }
//                } else if tutorialNum == 0 {
//                    tutorialNum = 4
//                    viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 4) { success in
//                    }
//                }
//            }
        }
        }
    }

struct roomListView_Previews: PreviewProvider {
    static var previews: some View {
        let user1 = User(id: "1", name: "ユーザー1", icon: "user1",rooms: ["1": true], tutorialNum: 1)
        let user2 = User(id: "2", name: "ユーザー2", icon: "user2", rooms: ["1": true], tutorialNum: 1)
        
        let users = [user1, user2]

        // userStatusesのデータを準備
        let userStatuses = ["1": UserStatus.available, "2": UserStatus.busy]

        // Roomのインスタンスを作成
        let room = Room(id: "", name: "部屋1", members: ["1": true, "2": true], statuses: ["status_0":"ステータス"], userStatuses: userStatuses)

        RoomListView()
//        RoomCreationPopupView()
//        let enteredStatusesBinding = Binding.constant(["ステータス1", "ステータス2"])
//        
//        StatusInputView(newRoomName: Binding.constant("テストルーム")
//, enteredStatuses: enteredStatusesBinding)
//        UserSearchView()
    }
}

