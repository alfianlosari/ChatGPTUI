import ChatGPTSwift
import SiriWaveView
import SwiftUI

public struct VoiceChatView<CustomContent: View>: View {
    
    @State var vm: VoiceChatViewModel<CustomContent>
    @State var isSymbolAnimating = false
    var loadingImageSystemName = "circle.dotted.circle"
    
    public init(voiceType: VoiceType = .alloy, model: ChatGPTModel = .gpt_hyphen_4o, systemText: String = "You're a helpful assistant", temperature: Double = 0.6, apiKey: String) where CustomContent == Text {
        self.vm = .init(voiceType: voiceType, model: model, systemText: systemText, temperature: temperature, apiKey: apiKey)
    }
    
    public init(customContentVM: VoiceChatViewModel<CustomContent>) {
        self.vm = customContentVM
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let response = vm.response {
                    ScrollView {
                        switch response {
                        case .attributed(let attributedOutput):
                            AttributedView(results: attributedOutput.results)
                            
                        case .rawText(let text):
                            if !text.isEmpty {
                                Text(text)
                                    .multilineTextAlignment(.leading)
                                    .textSelection(.enabled)
                            }
                            
                        case .customContent(let customViewProvider):
                            customViewProvider()
                        }
                        
                    }
                    .padding(.horizontal)
                    .listStyle(.plain)
                    Divider()
                }
            }.overlay { overlayView }
            
            HStack {
                if case .playingSpeech = self.vm.state {
                    SiriWaveView()
                        .power(power: vm.audioPower)
                        .frame(height: 128)
                }
                
                switch vm.state {
                case .idle, .error:
                    startCaptureButton
                case .recordingSpeech:
                    cancelRecordingButton
                case .processingSpeech, .playingSpeech:
                    cancelButton
                }
            }.padding()
        }
    }
    
    @ViewBuilder
    var overlayView: some View {
        switch vm.state {
        case .recordingSpeech:
            SiriWaveView()
                .power(power: vm.audioPower)
                .frame(height: 256)
            
        case .processingSpeech:
            Image(systemName: loadingImageSystemName)
                .symbolEffect(.bounce.up.byLayer, options: .repeating, value: isSymbolAnimating)
                #if os(iOS)
                .font(.system(size: 64))
                #else
                .font(.system(size: 128))
                #endif
                .onAppear { isSymbolAnimating = true }
                .onDisappear { isSymbolAnimating = false }
            
        case .error(let error):
            Text(error.localizedDescription)
                .foregroundStyle(.red)
                .font(.caption)
                .lineLimit(4)
                .padding(.horizontal)

        default: EmptyView()
        }
    }
    
    var startCaptureButton: some View {
        Button {
            vm.startCaptureAudio()
        } label: {
            Image(systemName: "mic.circle")
                .symbolRenderingMode(.multicolor)
            #if os(iOS)
                .font(.system(size: 64))
            #else
                .font(.system(size: 128))
                .padding(.bottom, 128)
            #endif
        }.buttonStyle(.borderless)
    }
    
    var cancelRecordingButton: some View {
        Button(role: .destructive) {
            vm.cancelRecording()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)
    }
    
    var cancelButton: some View {
        Button(role: .destructive) {
            vm.cancelProcessingTask()
        } label: {
            Image(systemName: "stop.circle.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.red)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)

    }
}

//#Preview {
//    SwiftUIView()
//}
