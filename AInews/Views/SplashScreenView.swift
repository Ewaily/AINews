//
//  SplashScreenView.swift
//  AInews
//
//  Created by Muhammad Ewaily on 13/05/2025.
//

import SwiftUI

struct SplashScreenView: View {
    // States for animation
    @State private var logoScale: CGFloat = 0.5 // Start smaller
    @State private var logoOpacity: Double = 0.0  // Start fully transparent
    @State private var textOpacity: Double = 0.0  // Text also starts transparent
    @State private var textOffsetY: CGFloat = 20 // Text starts slightly lower

    var body: some View {
        ZStack {
            // Use the appropriate system background color for the platform
            #if os(iOS) || os(tvOS) || os(visionOS)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            #elseif os(macOS)
            Color(NSColor.windowBackgroundColor) // Or NSColor.controlBackgroundColor for a slightly different shade
                .ignoresSafeArea()
            #else
            // Fallback for other platforms, or if you want a default
            Color.gray.opacity(0.1) // Example fallback
                .ignoresSafeArea()
            #endif

            VStack(spacing: 20) {
                Spacer()

                // Using AppIcon as requested.
                // Note: Appearance might vary, a dedicated launch image asset is usually preferred for splash screens.
                Image("LaunchLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("AI Developer News Hub")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(textOpacity)
                    .offset(y: textOffsetY)
                
                Spacer()
                Spacer() // Add more space at the bottom if needed

                // Copyright Notice
                Text("© \(currentYear) TrianglZ LLC. All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(textOpacity) // Optionally animate with text
                    .padding(.bottom, 20) // Ensure it's above the very bottom edge
            }
        }
        .onAppear {
            // Animate logo first
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Animate text shortly after the logo
            withAnimation(.easeInOut(duration: 0.7).delay(0.5)) {
                textOpacity = 1.0
                textOffsetY = 0
            }
            
            // The overall splash duration is still controlled in AINewsApp.swift
        }
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashScreenView()
                .preferredColorScheme(.light)
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
} 
