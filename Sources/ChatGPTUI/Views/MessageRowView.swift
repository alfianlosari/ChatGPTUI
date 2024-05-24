import SwiftUI

public struct MessageRowView<CustomContent: View>: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow<CustomContent>
    let retryCallback: (MessageRow<CustomContent>) -> Void
    
    var imageSize: CGSize {
        CGSize(width: 25, height: 25)
    }
    
    public init(message: MessageRow<CustomContent>, retryCallback: @escaping (MessageRow<CustomContent>) -> Void) {
        self.message = message
        self.retryCallback = retryCallback
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            messageRow(rowType: message.send, image: message.sendImage, bgColor: colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            if let response = message.response {
                Divider()
                messageRow(rowType: response, image: message.responseImage, bgColor: colorScheme == .light ? .gray.opacity(0.1) : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1), responseError: message.responseError, showDotLoading: message.isPrompting)
                Divider()
            }
        }
    }
    
    func messageRow(rowType: MessageRowType<CustomContent>, image: String?, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 24) {
            messageRowContent(rowType: rowType, image: image, responseError: responseError, showDotLoading: showDotLoading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }
    
    @ViewBuilder
    func messageRowContent(rowType: MessageRowType<CustomContent>, image: String?, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        if let image = image {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: imageSize.width, height: imageSize.height)
                } placeholder: {
                    ProgressView()
                }

            } else {
                Image(image)
                    .resizable()
                    .frame(width: imageSize.width, height: imageSize.height)
            }
        }
                
        VStack(alignment: .leading) {
            switch rowType {
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
                        
            if let error = responseError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Regenerate response") {
                    retryCallback(message)
                }
                .foregroundColor(.accentColor)
                .padding(.top)
            }
            
            if showDotLoading {
                DotLoadingView()
                    .frame(width: 60, height: 30)
            }
        }
    }
 
}


//#Preview {
//    SwiftUIView()
//}
