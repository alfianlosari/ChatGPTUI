import Foundation
import SwiftUI

public struct TextChatView<CustomContent: View>: View {
        
    @Environment(\.colorScheme) var colorScheme
    
    @State var vm: TextChatViewModel<CustomContent>
    @FocusState var isTextFieldFocused: Bool
    
    public init(senderImage: String? = nil, botImage: String? = nil, apiKey: String) where CustomContent == Text {
        self.vm = .init(senderImage: senderImage, botImage: botImage, apiKey: apiKey)
    }
    
    public init(customContentVM: TextChatViewModel<CustomContent>) {
        self.vm = customContentVM
    }
    
    public var body: some View {
        chatListView
            .toolbar {
                ToolbarItemGroup(placement: .destructiveAction) {
                    Button("Clear", role: .destructive) {
                        vm.clearMessages()
                    }
                    .disabled(vm.isPrompting)
                }
            }
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { message in
                            MessageRowView(message: message) { message in
                                Task { @MainActor in
                                    await vm.retry(message: message)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                Divider()
                bottomView(image: vm.senderImage, proxy: proxy)
                Spacer()
            }
            .onChange(of: vm.messages.last?.responseText) { scrollToBottom(proxy: proxy) }
        }
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
    
    func bottomView(image: String?, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if let image {
                if image.hasPrefix("http"), let url = URL(string: image) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 30, height: 30)
                    } placeholder: {
                        ProgressView()
                    }

                } else {
                    Image(image)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            
            TextField("Send message", text: $vm.inputMessage, axis: .vertical)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .disabled(vm.isPrompting)
            
            if vm.isPrompting {
                Button {
                    vm.cancelStreamingResponse()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await vm.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                .keyboardShortcut(.defaultAction)
                .foregroundColor(.accentColor)
                #endif
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}
