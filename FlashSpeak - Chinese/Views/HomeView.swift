import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                Text("FlashSpeak")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("中文")
                    .font(.title)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(spacing: 20) {
                    NavigationLink(destination: NewPhraseView()) {
                        Label("New Phrase", systemImage: "mic.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: PracticeView()) {
                        Label("Practice", systemImage: "brain.head.profile")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}//
//  HomeView.swift
//  FlashSpeak - Chinese
//
//  Created by Vlad Tamas on 12/8/25.
//

