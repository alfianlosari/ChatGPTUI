import Foundation
import SwiftUI

public struct AttributedView: View {
    
    public let results: [ParserResult]
    
    public init(results: [ParserResult]) {
        self.results = results
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(results) { parsed in
                if parsed.isCodeBlock {
                    CodeBlockView(parserResult: parsed)
                        .padding(.bottom)
                } else {
                    Text(parsed.attributedString)
                        .textSelection(.enabled)
                }
            }
        }
    }
}
