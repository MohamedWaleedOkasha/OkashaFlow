// import SwiftUI
// import AVFoundation
// import Speech

// struct VoiceAssistantView: View {
//     @StateObject private var viewModel = VoiceAssistantViewModel()
//     @Environment(\.colorScheme) var colorScheme
    
//     var body: some View {
//         VStack(spacing: 20) {
//             // Transcription Display
//             ScrollView {
//                 VStack(alignment: .leading, spacing: 16) {
//                     if !viewModel.transcribedText.isEmpty {
//                         TranscriptionBubble(text: viewModel.transcribedText, type: .user)
//                     }
                    
//                     if !viewModel.aiResponse.isEmpty {
//                         TranscriptionBubble(text: viewModel.aiResponse, type: .ai)
//                     }
//                 }
//                 .padding()
//             }
//             .frame(maxWidth: .infinity)
//             .background(
//                 RoundedRectangle(cornerRadius: 12)
//                     .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
//             )
//             .padding()
            
//             // Recording Status
//             if viewModel.isRecording {
//                 Text("Listening...")
//                     .foregroundColor(.blue)
//                     .font(.headline)
//             }
            
//             // Microphone Button
//             Button(action: {
//                 viewModel.toggleRecording()
//             }) {
//                 ZStack {
//                     Circle()
//                         .fill(viewModel.isRecording ? Color.red : Color.blue)
//                         .frame(width: 80, height: 80)
//                         .shadow(radius: 5)
                    
//                     Image(systemName: "mic.fill")
//                         .resizable()
//                         .scaledToFit()
//                         .frame(width: 30, height: 30)
//                         .foregroundColor(.white)
//                 }
//             }
//             .padding(.bottom, 30)
//         }
//         .navigationTitle("Voice Assistant")
//         .alert("Error", isPresented: $viewModel.showError) {
//             Button("OK", role: .cancel) {}
//         } message: {
//             Text(viewModel.errorMessage)
//         }
//     }
// }

// struct TranscriptionBubble: View {
//     let text: String
//     let type: MessageType
    
//     enum MessageType {
//         case user
//         case ai
//     }
    
//     var body: some View {
//         HStack {
//             if type == .user { Spacer() }
            
//             Text(text)
//                 .padding()
//                 .background(
//                     RoundedRectangle(cornerRadius: 16)
//                         .fill(bubbleColor)
//                 )
//                 .foregroundColor(type == .ai ? .primary : .white)
            
//             if type == .ai { Spacer() }
//         }
//     }
    
//     private var bubbleColor: Color {
//         switch type {
//         case .user: return .blue
//         case .ai: return Color(.systemGray5)
//         }
//     }
// } 