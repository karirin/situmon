//
//  RoomCreationPopupView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/12/03.
//

import SwiftUI
import Firebase

struct RoomCreationPopupView: View {
    @State private var newRoomName = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showAlert = false
    @State private var selectedStatuses: [UserStatus] = []
    @State private var statusInput = ""
    @State private var enteredStatuses: [String] = []
    @State private var showStatusInputView = false
    @State private var buttonRect: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum: Int = 0
    @State private var currentUser: User?

    var body: some View {
        
    NavigationView {
            ZStack{
                VStack(spacing: 20){
                    HStack {
                        Text("グループ名を入力してください")
                            .font(.system(size: 24))
                            .foregroundColor(Color("fontGray"))
                    }
                    Text("20文字以下で入力してください")
                        .font(.system(size: 16))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    ZStack(alignment: .trailing){
                        TextField("グループ名", text: $newRoomName)
                            .onChange(of: newRoomName) { newValue in
                                if newValue.count > 20 {
                                    newRoomName = String(newValue.prefix(20))
                                }
                            }
                            .font(.system(size: 30))
                            .padding(.horizontal,20)
                            .padding(.trailing, newRoomName.isEmpty ? 0 : 40)
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                            })
                        
                        if !newRoomName.isEmpty {
                            Button(action: {
                                self.newRoomName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .font(.system(size: 30))
                            .padding(.trailing, 5)
                        }
                    }
                    Button(action: {
                        viewModel.checkIfGroupNameExists(newRoomName) { exists in
                            if exists {
                                showAlert = true
                            }else{
                                showStatusInputView = true
                            }
                        }
                    }) {
                        // ボタンの背景
                        Text("次へ")
                            .padding(.vertical,10)
                            .padding(.horizontal,25)
                            .font(.headline)
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 25)
                                .fill(newRoomName.isEmpty ? Color.gray : Color("btnColor")))
                        //                .fill(Color("btnColor")))
                        //                        .opacity(goal.isEmpty ? 0.5 : 1.0)
                            .opacity(newRoomName.isEmpty ? 0.5 : 1.0)
                            .padding()
                    }
                    .disabled(newRoomName.isEmpty)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("エラー"),
                            message: Text("グループ名が既に使われています"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    NavigationLink(destination: StatusInputView(newRoomName: $newRoomName, enteredStatuses: $enteredStatuses)
                                   , isActive: $showStatusInputView) {
                        EmptyView() // 非表示のビュー
                    }

                                   .navigationBarBackButtonHidden(true)
                                   .navigationBarItems(leading: Button(action: {
                                       self.presentationMode.wrappedValue.dismiss()
                                   }) {
                                       Image(systemName: "chevron.left")
                                           .foregroundColor(.black)
                                       Text("戻る")
                                           .foregroundColor(.black)
                                   })
                    Spacer()
                }
            
//                if tutorialNum == 2 {
//                    GeometryReader { geometry in
//                        Color.black.opacity(0.5)
//                            .overlay(
//                        RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                    .frame(width: buttonRect.width, height: buttonRect.height + 10)
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
//                        Image("上矢印")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .padding(.trailing, 45.0)
//                            Text("作成するグループの名前を入力します。")
//                                .font(.system(size: 20.0))
//                                .padding(.all, 20.0)
//                                .background(Color.white)
//                                .cornerRadius(4.0)
//                                .padding(.horizontal, 3)
//                                .foregroundColor(Color("fontGray"))
//                        }
//                        .background(GeometryReader { geometry in
//                            Path { _ in
//                                DispatchQueue.main.async {
//                                    self.bubbleHeight = geometry.size.height - 160
//                                }
//                            }
//                        })
//                        Spacer()
//                    }
//                    .ignoresSafeArea()
//                    
//                }

            }                                   
//            .onPreferenceChange(ViewPositionKey.self) { positions in
//                self.buttonRect = positions.first ?? .zero
//            }
//            .onTapGesture {
//                    print("onTapGesturehhh")
//                    if self.tutorialNum == 2 {
//                        self.tutorialNum = 3 // タップでチュートリアルを終了
//                        viewModel.authenticateUser { isAuthenticated in
//                            if isAuthenticated {
//                                viewModel.updateTutorialNum(userId: viewModel.currentUserId ?? "", tutorialNum: 3) { success in
//                                    // データベースのアップデートが成功したかどうかをハンドリング
//                                }
//                            }
//                        }
//                    }
//                }
            .onAppear {
                viewModel.authenticateUser { isAuthenticated in
                    if isAuthenticated {
                        currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
    //                        print(currentUser)
                        // 認証成功時の処理
    //                        print("認証に成功しました")
//                            if currentUser!.tutorialNum == 2{
//                            self.tutorialNum = currentUser!.tutorialNum
//                        print("dddd")
//                        print(self.tutorialNum)
//                            }
                    } else {
                        // 認証失敗時の処理
                    }
                }
            }
//            .padding()
                
                    
        }

            
//        }
    }
}


#Preview {
    RoomCreationPopupView()
}
