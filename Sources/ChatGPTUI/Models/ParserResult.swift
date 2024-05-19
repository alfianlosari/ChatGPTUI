import Foundation

public struct ParserResult: Identifiable {
    
    public let id = UUID()
    public let attributedString: AttributedString
    public let isCodeBlock: Bool
    public let codeBlockLanguage: String?
    
    public init(attributedString: AttributedString, isCodeBlock: Bool, codeBlockLanguage: String?) {
        self.attributedString = attributedString
        self.isCodeBlock = isCodeBlock
        self.codeBlockLanguage = codeBlockLanguage
    }
}
