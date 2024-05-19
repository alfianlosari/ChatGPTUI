import Foundation
import SwiftUI

public struct MessageRow<CustomContent: View>: Identifiable {
    
    public let id = UUID()
    public var isPrompting: Bool
    
    public let sendImage: String?
    public var send: MessageRowType<CustomContent>
    public var sendText: String {
        send.text
    }
    
    public let responseImage: String?
    public var response: MessageRowType<CustomContent>?
    public var responseText: String? {
        response?.text
    }
    
    public var responseError: String?
    
    public init(isPrompting: Bool, sendImage: String?, send: MessageRowType<CustomContent>, responseImage: String?, response: MessageRowType<CustomContent>? = nil, responseError: String? = nil) {
        self.isPrompting = isPrompting
        self.sendImage = sendImage
        self.send = send
        self.responseImage = responseImage
        self.response = response
        self.responseError = responseError
    }
}

public enum MessageRowType<CustomContent: View> {
    case attributed(AttributedOutput)
    case rawText(String)
    case customContent(() -> CustomContent)
    
    public var text: String {
        switch self {
        case .attributed(let attributedOutput):
            return attributedOutput.string
        case .rawText(let string):
            return string
        case .customContent(let viewProvider):
            return "custom \(String(describing: viewProvider))"
        }
    }
}

public struct AttributedOutput {
    public let string: String
    public let results: [ParserResult]
    
    public init(string: String, results: [ParserResult]) {
        self.string = string
        self.results = results
    }
}
