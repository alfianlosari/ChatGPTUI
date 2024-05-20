import Foundation

public enum VoiceChatState {
    case idle
    case recordingSpeech
    case processingSpeech
    case playingSpeech
    case error(Error)
    
    public var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
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
