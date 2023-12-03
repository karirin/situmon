//
//  StatusInputView.swift
//  situmon
//
//  Created by hashimo ryoya on 2023/12/03.
//

import SwiftUI
import Firebase

struct StatusInputView: View {
    @Binding var newRoomName: String
    @Binding var enteredStatuses: [String]
    @State private var status1: String = ""
    @State private var status2: String = ""
    @State private var status3: String = ""
    @ObservedObject var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var isContentView: Bool = false
    @State private var showAlert = false
    @State private var buttonRect: CGRect = .zero
    @State private var buttonRect2: CGRect = .zero
    @State private var bubbleHeight: CGFloat = 0.0
    @State private var tutorialNum: Int = 0
    @State private var currentUser: User?

    var body: some View {
        ZStack{
            VStack(spacing: 20) {
                HStack {
                    Text("ステータスを入力してください")
                        .font(.system(size: 24))
                        .foregroundColor(Color("fontGray"))
                }
                
                Text("３つステータスを入力してください\n（例）ひま、普通、忙しい")
                    .font(.system(size: 16))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 5)
                
                // 1つ目のステータス入力フォーム
                VStack{
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.green)
                                .frame(width: 15, height: 15)
                            Text("：ステータスを表す色")
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("1つ目のステータス", text: $status1)
                            .onChange(of: status1) { newValue in
                                if newValue.count > 10 {
                                    status1 = String(newValue.prefix(10))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 20))
                            .padding(5)
                            .padding(.horizontal)
                    }
                    // 2つ目のステータス入力フォーム
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.yellow)
                                .frame(width: 15, height: 15)
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("2つ目のステータス", text: $status2)
                            .onChange(of: status2) { newValue in
                                if newValue.count > 10 {
                                    status2 = String(newValue.prefix(10))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 20))
                            .padding(5)
                            .padding(.horizontal)
                    }
                    // 3つ目のステータス入力フォーム
                    VStack(spacing: 5){
                        HStack{
                            Circle()
                                .fill(.red)
                                .frame(width: 15, height: 15)
                            Spacer()
                        }
                        .padding(.leading,25)
                        TextField("3つ目のステータス", text: $status3)
                            .onChange(of: status3) { newValue in
                                if newValue.count > 10 {
                                    status3 = String(newValue.prefix(10))
                                }
                            }
                            .font(.system(size: 20))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(5)
                            .padding(.horizontal)
                    }
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ViewPositionKey.self, value: [geometry.frame(in: .global)])
                })
                Button(action: {
                    // デフォルトのステータスを各テキストフィールドに設定
                    status1 = "ひま"
                    status2 = "普通"
                    status3 = "忙しい"
                }) {
                    Text("サンプルを入力")
                        .padding(.vertical,10)
                        .padding(.horizontal,25)
                        .font(.headline)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(Color("btnColor")))
                        .opacity(1.0)
                        .padding()
                }
//                .background(GeometryReader { geometry in
//                    Color.clear.preference(key: ViewPositionKey1.self, value: [geometry.frame(in: .global)])
//                })
                .padding(.bottom,-30)
                Button(action: {
                    if status1.isEmpty || status2.isEmpty || status3.isEmpty {
                        showAlert = true
                    } else {
                        enteredStatuses.append(contentsOf: [status1, status2, status3])
                        viewModel.createRoom(withName: newRoomName, statuses: enteredStatuses, userStatuses: enteredStatuses)
                        isContentView = true
                    }
                }) {
                    Text("グループを作成")
                        .padding(.vertical,10)
                        .padding(.horizontal,25)
                        .font(.headline)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(Color("btnColor")))
                        .opacity(1.0)
                        .padding()
                }
                
                NavigationLink("", destination: RoomListView().navigationBarBackButtonHidden(true), isActive: $isContentView)
            }
            
//            if self.tutorialNum == 3 {
//                GeometryReader { geometry in
//                    Color.black.opacity(0.5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                                .frame(width: buttonRect.width - 20, height: buttonRect.height + 10)
//                                .position(x: buttonRect.midX, y: buttonRect.midY)
//                                .blendMode(.destinationOut)
//                        )
//                        .ignoresSafeArea()
//                        .compositingGroup()
//                        .background(.clear)
//                }
//                VStack {
//                    Spacer()
//                        .frame(height: buttonRect.minY - bubbleHeight)
//                    VStack(alignment: .trailing, spacing: .zero) {
//                        Text("グループ内で使用するステータスを入力します。")
//                            .font(.system(size: 20.0))
//                            .padding(.all, 10.0)
//                            .background(Color.white)
//                            .cornerRadius(4.0)
//                            .padding(.horizontal, 3)
//                            .foregroundColor(Color("fontGray"))
//                        Image("下矢印")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .padding(.trailing, 45.0)
//                    }
//                    .background(GeometryReader { geometry in
//                        Path { _ in
//                            DispatchQueue.main.async {
//                                self.bubbleHeight = geometry.size.height + 10
//                            }
//                        }
//                    })
//                    Spacer()
//                }
//                .ignoresSafeArea()
//            }
        }
//        .onTapGesture {
//            if self.tutorialNum == 3 {
//                self.tutorialNum = 0
//                print("currentUserid")
//                print(currentUser?.id)
//                viewModel.updateTutorialNum(userId: currentUser?.id ?? "", tutorialNum: 4) { success in
//                }
//            }
//        }
        .onAppear {
            viewModel.authenticateUser { isAuthenticated in
                if isAuthenticated {
                    currentUser = viewModel.users.first(where: { $0.id == viewModel.currentUserId })
//                    if currentUser!.tutorialNum == 3{
//                    self.tutorialNum = currentUser!.tutorialNum
//                    }
                } else {
                    // 認証失敗時の処理
                }
            }
        }
//        .onPreferenceChange(ViewPositionKey.self) { positions in
//            self.buttonRect = positions.first ?? .zero
//        }
//        .onPreferenceChange(ViewPositionKey1.self) { positions in
//            self.buttonRect2 = positions.first ?? .zero
//        }
        
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
            Text("戻る")
                .foregroundColor(.black)
        })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("エラー"),
                message: Text("すべてのステータスを入力してください"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
struct StatusInputView_Previews: PreviewProvider {
    static var previews: some View {
        
        let enteredStatusesBinding = Binding.constant(["ステータス1", "ステータス2"])
        
        StatusInputView(newRoomName: Binding.constant("テストルーム")
                        , enteredStatuses: enteredStatusesBinding)
    }
}
