import ChatGPTSwift
import Foundation
import Observation
import SwiftUI
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

@Observable
public class TextChatViewModel<CustomContent: View> {
        
    public var messages: [MessageRow<CustomContent>] = []
    public var inputMessage = ""
    public var isPrompting = false
    public var task: Task<Void, Never>?
    public var senderImage: String?
    public var botImage: String?
    
    let api: ChatGPTAPI
    
    public init(messages: [MessageRow<CustomContent>] = [], senderImage: String? = nil, botImage: String? = nil, apiKey: String) {
        self.messages = messages
        self.senderImage = senderImage
        self.botImage = botImage
        self.api = ChatGPTAPI(apiKey: apiKey)
    }
    
    @MainActor
    open func sendTapped() async {
        self.task = Task {
            let text = inputMessage
            inputMessage = ""
            await send(text: text)
        }
    }
    
    @MainActor
    open func clearMessages() {
        api.deleteHistoryList()
        withAnimation { [weak self] in
            self?.messages = []
        }
    }
    
    open func cancelStreamingResponse() {
        self.task?.cancel()
        self.task = nil
    }
    
    @MainActor
    open func send(text: String) async {
        isPrompting = true
        var messageRow = MessageRow<CustomContent>(
            isPrompting: true,
            sendImage: senderImage,
            send: .rawText(text),
            responseImage: botImage,
            response: .rawText(""),
            responseError: nil)
        
        var streamText = ""
        do {
            let parsingTask = ResponseParsingTask()
            let attributedSend = await parsingTask.parse(text: text)
            try Task.checkCancellation()
            messageRow.send = .attributed(attributedSend)
            
            self.messages.append(messageRow)
            let parserThresholdTextCount = 64
            var currentTextCount = 0
            var currentOutput: AttributedOutput?
            
            let stream = try await api.sendMessageStream(text: text, model: .init(rawValue: "gpt-4o") ?? .gpt_hyphen_4)
            for try await text in stream {
                streamText += text
                currentTextCount += text.count
                
                if currentTextCount >= parserThresholdTextCount || text.contains("```") {
                    currentOutput = await parsingTask.parse(text: streamText)
                    try Task.checkCancellation()
                    currentTextCount = 0
                }

                if let currentOutput = currentOutput, !currentOutput.results.isEmpty {
                    let suffixText = streamText.trimmingPrefix(currentOutput.string)
                    var results = currentOutput.results
                    let lastResult = results[results.count - 1]
                    var lastAttrString = lastResult.attributedString
                    if lastResult.isCodeBlock {
                        #if os(macOS)
                        lastAttrString.append(AttributedString(String(suffixText), attributes: .init([.font: NSFont.systemFont(ofSize: 12).apply(newTraits: .monoSpace), .foregroundColor: NSColor.white])))
                        #else
                        lastAttrString.append(AttributedString(String(suffixText), attributes: .init([.font: UIFont.systemFont(ofSize: 12).apply(newTraits: .traitMonoSpace), .foregroundColor: UIColor.white])))
                        #endif
                        
                    } else {
                        lastAttrString.append(AttributedString(String(suffixText)))
                    }
                    results[results.count - 1] = ParserResult(attributedString: lastAttrString, isCodeBlock: lastResult.isCodeBlock, codeBlockLanguage: lastResult.codeBlockLanguage)
                    messageRow.response = .attributed(.init(string: streamText, results: results))
                } else {
                    messageRow.response = .attributed(.init(string: streamText, results: [
                        ParserResult(attributedString: AttributedString(stringLiteral: streamText), isCodeBlock: false, codeBlockLanguage: nil)
                    ]))
                }

                self.messages[self.messages.count - 1] = messageRow
                if let currentString = currentOutput?.string, currentString != streamText {
                    let output = await parsingTask.parse(text: streamText)
                    try Task.checkCancellation()
                    messageRow.response = .attributed(output)
                }
            }
        } catch is CancellationError {
            messageRow.responseError = "The response was cancelled"
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        if messageRow.response == nil {
            messageRow.response = .rawText(streamText)
        }
  
        messageRow.isPrompting = false
        self.messages[self.messages.count - 1] = messageRow
        self.isPrompting = false
    }
    
    @MainActor
    open func sendWithoutStream(text: String) async {
        isPrompting = true
        var messageRow = MessageRow<CustomContent>(
            isPrompting: true,
            sendImage: senderImage,
            send: .rawText(text),
            responseImage: botImage,
            response: .rawText(""),
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let responseText = try await api.sendMessage(text: text, model: .init(rawValue: "gpt-4o") ?? .gpt_hyphen_4)
            try Task.checkCancellation()
            
            let parsingTask = ResponseParsingTask()
            let output = await parsingTask.parse(text: responseText)
            try Task.checkCancellation()
            
            messageRow.response = .attributed(output)
            
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isPrompting = false
        self.messages[self.messages.count - 1] = messageRow
        isPrompting = false
    }
    
    
    @MainActor
    open func retry(message: MessageRow<CustomContent>) async {
        self.task = Task {
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
                return
            }
            self.messages.remove(at: index)
            await send(text: message.sendText)
        }
    }
    
    func updateLastMessageInList(updateHandler: (inout MessageRow<CustomContent>) -> Void) {
        var messageRow = messages[self.messages.count - 1]
        updateHandler(&messageRow)
        self.messages[self.messages.count - 1] = messageRow
    }
    
}


