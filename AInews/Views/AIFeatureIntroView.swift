import SwiftUI

struct AIFeatureIntroView: View {
    @Binding var showIntro: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                Text("On-Device AI Summarization")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                // AI icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.purple)
                }
                .padding(.bottom, 10)
                
                // Feature description
                VStack(alignment: .leading, spacing: 25) {
                    FeatureItem(
                        icon: "cpu",
                        title: "Powered by CoreML",
                        description: "Uses Apple's on-device machine learning to generate article summaries without sending your data to external servers."
                    )
                    
                    FeatureItem(
                        icon: "doc.text.magnifyingglass",
                        title: "Smart Content Extraction",
                        description: "Automatically identifies and processes the main content from articles, filtering out ads and unnecessary elements."
                    )
                    
                    FeatureItem(
                        icon: "bolt.shield",
                        title: "Privacy First",
                        description: "All processing happens on your device. Your reading habits and interests remain private."
                    )
                    
                    FeatureItem(
                        icon: "ellipsis.bubble",
                        title: "Natural Language Processing",
                        description: "Analyzes text structure to extract the most important information and create concise summaries."
                    )
                }
                .padding(.horizontal, 30)
                
                // Get started button
                Button(action: {
                    withAnimation {
                        showIntro = false
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        // Use platform-specific background color that works on all platforms
        .background(colorScheme == .dark ? Color.black : Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.all)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AIFeatureIntroView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AIFeatureIntroView(showIntro: .constant(true))
                .preferredColorScheme(.light)
            
            AIFeatureIntroView(showIntro: .constant(true))
                .preferredColorScheme(.dark)
        }
    }
} 