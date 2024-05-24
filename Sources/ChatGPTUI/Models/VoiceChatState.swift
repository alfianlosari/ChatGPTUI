import Foundation
import SwiftUI

public enum VoiceChatState<Content: View> {
    case idle(ChatResponse<Content>?)
    case recordingSpeech
    case processingSpeech
    case playingSpeech(ChatResponse<Content>)
    case error(Error)
    
    public var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
    
    public var idleResponse: ChatResponse<Content>? {
        if case .idle(let chatResponse) = self {
            return chatResponse
        }
        return nil
    }
    
    public var playingSpeechResponse: ChatResponse<Content>? {
        if case .playingSpeech(let chatResponse) = self {
            return chatResponse
        }
        return nil
    }
    
    public var isRecordingSpeech: Bool {
        if case .recordingSpeech = self {
            return true
        }
        return false
    }
    
    public var isProcessingSpeech: Bool {
        if case .processingSpeech = self {
            return true
        }
        return false
    }
    
    public var isPlayingSpeech: Bool {
        if case .playingSpeech = self {
            return true
        }
        return false
    }
    
    public var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

}
