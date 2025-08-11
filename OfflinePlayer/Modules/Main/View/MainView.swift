//
//  MainView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 11.08.2025.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var vm = MainViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Это я показал как надо пушить на другой экран
            // Потом удали все что не надо
            Button {
                vm.pushToSecond()
            } label: {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.blue)
                    .frame(width: 200, height: 50)
            }

        }
        .task {
            vm.attach(router: router)
        }
    }
}

#Preview {
    MainView()
}


// Это тестовая view
// Потом удали
struct SecondView: View {
    var body: some View {
        ZStack {
            Color.yellow
                .ignoresSafeArea()
            Text("Second View")
        }
        .navigationBarHidden(true)
    }
}
