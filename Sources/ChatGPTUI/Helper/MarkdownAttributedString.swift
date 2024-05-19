import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import Markdown
import Highlighter

/// Based on the source code from Christian Selig
/// https://github.com/christianselig/Markdownosaur/blob/main/Sources/Markdownosaur/Markdownosaur.swift

public struct MarkdownAttributedStringParser: MarkupVisitor {
    
    #if os(macOS)
    let baseFontSize: CGFloat = NSFont.preferredFont(forTextStyle: .body).pointSize
    #else
    let baseFontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize
    #endif
    
    let highlighter: Highlighter = {
        let highlighter = Highlighter()!
        highlighter.setTheme("stackoverflow-dark")
        return highlighter
    }()
    
    let newLineFontSize: CGFloat = 12

    public init() {}
    
    public mutating func attributedString(from document: Document) -> NSAttributedString {
        return visit(document)
    }
    
    mutating func parserResults(from document: Document) -> [ParserResult] {
        var results = [ParserResult]()
        var currentAttrString = NSMutableAttributedString()
        
        func appendCurrentAttrString() {
            if !currentAttrString.string.isEmpty {
                #if os(macOS)
                let currentAttrStringToAppend = (try? AttributedString(currentAttrString, including: \.appKit)) ?? AttributedString(stringLiteral: currentAttrString.string)
                #else
                let currentAttrStringToAppend = (try? AttributedString(currentAttrString, including: \.uiKit)) ?? AttributedString(stringLiteral: currentAttrString.string)
                #endif

                results.append(.init(attributedString: currentAttrStringToAppend, isCodeBlock: false, codeBlockLanguage: nil))
            }
        }
        
        document.children.forEach { markup in
            let attrString = visit(markup)
            if let codeBlock = markup as? CodeBlock {
                appendCurrentAttrString()
                #if os(macOS)
                let attrStringToAppend = (try? AttributedString(attrString, including: \.appKit)) ?? AttributedString(stringLiteral: attrString.string)
                #else
                let attrStringToAppend = (try? AttributedString(attrString, including: \.uiKit)) ?? AttributedString(stringLiteral: attrString.string)
                #endif
                
                
                results.append(.init(attributedString: attrStringToAppend, isCodeBlock: true, codeBlockLanguage: codeBlock.language))
                currentAttrString = NSMutableAttributedString()
            } else {
                currentAttrString.append(attrString)
            }
        }
         
        appendCurrentAttrString()
        return results
    }
    
    mutating public func defaultVisit(_ markup: Markup) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in markup.children {
            result.append(visit(child))
        }
        
        return result
    }
    
    mutating public func visitText(_ text: Text) -> NSAttributedString {
        #if os(macOS)
        NSAttributedString(string: text.plainText, attributes: [.font: NSFont.systemFont(ofSize: baseFontSize, weight: .regular)])
        #else
        NSAttributedString(string: text.plainText, attributes: [.font: UIFont.systemFont(ofSize: baseFontSize, weight: .regular)])
        #endif
    }
    
    mutating public func visitEmphasis(_ emphasis: Emphasis) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in emphasis.children {
            result.append(visit(child))
        }
        
        result.applyEmphasis()
        
        return result
    }
    
    mutating public func visitStrong(_ strong: Strong) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in strong.children {
            result.append(visit(child))
        }
        
        result.applyStrong()
        
        return result
    }
    
    mutating public func visitParagraph(_ paragraph: Paragraph) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in paragraph.children {
            result.append(visit(child))
        }
        
        if paragraph.hasSuccessor {
            result.append(paragraph.isContainedInList ? .singleNewline(withFontSize: newLineFontSize) : .doubleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
    
    mutating public func visitHeading(_ heading: Heading) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in heading.children {
            result.append(visit(child))
        }
        
        result.applyHeading(withLevel: heading.level)
        
        if heading.hasSuccessor {
            result.append(.doubleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
    
    mutating public func visitLink(_ link: Link) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in link.children {
            result.append(visit(child))
        }
        
        let url = link.destination != nil ? URL(string: link.destination!) : nil
        
        result.applyLink(withURL: url)
        
        return result
    }
    
    mutating public func visitInlineCode(_ inlineCode: InlineCode) -> NSAttributedString {
        #if os(macOS)
        NSAttributedString(string: inlineCode.code, attributes: [.font: NSFont.monospacedSystemFont(ofSize: baseFontSize - 1.0, weight: .regular), .foregroundColor: NSColor.systemPink])
        #else
        NSAttributedString(string: inlineCode.code, attributes: [.font: UIFont.monospacedSystemFont(ofSize: baseFontSize - 1.0, weight: .regular), .foregroundColor: UIColor.systemPink])
        #endif
        
    }
    
    public func visitCodeBlock(_ codeBlock: CodeBlock) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: highlighter.highlight(codeBlock.code, as: codeBlock.language) ?? NSAttributedString(string: codeBlock.code))
        
        if codeBlock.hasSuccessor {
            result.append(.singleNewline(withFontSize: newLineFontSize))
        }
    
        return result
    }
    
    mutating public func visitStrikethrough(_ strikethrough: Strikethrough) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in strikethrough.children {
            result.append(visit(child))
        }
        
        result.applyStrikethrough()
        
        return result
    }
    
    mutating public func visitUnorderedList(_ unorderedList: UnorderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        #if os(macOS)
        let font = NSFont.systemFont(ofSize: baseFontSize, weight: .regular)
        #else
        let font = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)
        #endif
                
        for listItem in unorderedList.listItems {
            var listItemAttributes: [NSAttributedString.Key: Any] = [:]
            
            let listItemParagraphStyle = NSMutableParagraphStyle()
            
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(unorderedList.listDepth))
            let spacingFromIndex: CGFloat = 8.0
            let bulletWidth = ceil(NSAttributedString(string: "•", attributes: [.font: font]).size().width)
            let firstTabLocation = leftMarginOffset + bulletWidth
            let secondTabLocation = firstTabLocation + spacingFromIndex
            
            listItemParagraphStyle.tabStops = [
                NSTextTab(textAlignment: .right, location: firstTabLocation),
                NSTextTab(textAlignment: .left, location: secondTabLocation)
            ]
            
            listItemParagraphStyle.headIndent = secondTabLocation
            
            listItemAttributes[.paragraphStyle] = listItemParagraphStyle
            #if os(macOS)
            listItemAttributes[.font] = NSFont.systemFont(ofSize: baseFontSize, weight: .regular)
            #else
            listItemAttributes[.font] = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)
            #endif
            listItemAttributes[.listDepth] = unorderedList.listDepth
            
            let listItemAttributedString = visit(listItem).mutableCopy() as! NSMutableAttributedString
            listItemAttributedString.insert(NSAttributedString(string: "\t•\t", attributes: listItemAttributes), at: 0)
            
            result.append(listItemAttributedString)
        }
        
        if unorderedList.hasSuccessor {
            result.append(.doubleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
    
    mutating public func visitListItem(_ listItem: ListItem) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in listItem.children {
            result.append(visit(child))
        }
        
        if listItem.hasSuccessor {
            result.append(.singleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
    
    mutating public func visitOrderedList(_ orderedList: OrderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for (index, listItem) in orderedList.listItems.enumerated() {
            var listItemAttributes: [NSAttributedString.Key: Any] = [:]
            #if os(macOS)
            let font = NSFont.systemFont(ofSize: baseFontSize, weight: .regular)
            let numeralFont = NSFont.monospacedDigitSystemFont(ofSize: baseFontSize, weight: .regular)
            #else
            let font = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)
            let numeralFont = UIFont.monospacedDigitSystemFont(ofSize: baseFontSize, weight: .regular)
            #endif
            
            
            let listItemParagraphStyle = NSMutableParagraphStyle()
            
            // Implement a base amount to be spaced from the left side at all times to better visually differentiate it as a list
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(orderedList.listDepth))
            
            // Grab the highest number to be displayed and measure its width (yes normally some digits are wider than others but since we're using the numeral mono font all will be the same width in this case)
            let highestNumberInList = orderedList.childCount
            let numeralColumnWidth = ceil(NSAttributedString(string: "\(highestNumberInList).", attributes: [.font: numeralFont]).size().width)
            
            let spacingFromIndex: CGFloat = 8.0
            let firstTabLocation = leftMarginOffset + numeralColumnWidth
            let secondTabLocation = firstTabLocation + spacingFromIndex
            
            listItemParagraphStyle.tabStops = [
                NSTextTab(textAlignment: .right, location: firstTabLocation),
                NSTextTab(textAlignment: .left, location: secondTabLocation)
            ]
            
            listItemParagraphStyle.headIndent = secondTabLocation
            
            listItemAttributes[.paragraphStyle] = listItemParagraphStyle
            listItemAttributes[.font] = font
            listItemAttributes[.listDepth] = orderedList.listDepth

            let listItemAttributedString = visit(listItem).mutableCopy() as! NSMutableAttributedString
            
            // Same as the normal list attributes, but for prettiness in formatting we want to use the cool monospaced numeral font
            var numberAttributes = listItemAttributes
            numberAttributes[.font] = numeralFont
            
            let numberAttributedString = NSAttributedString(string: "\t\(index + 1).\t", attributes: numberAttributes)
            listItemAttributedString.insert(numberAttributedString, at: 0)
            
            result.append(listItemAttributedString)
        }
        
        if orderedList.hasSuccessor {
            result.append(orderedList.isContainedInList ? .singleNewline(withFontSize: newLineFontSize) : .doubleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
    
    mutating public func visitBlockQuote(_ blockQuote: BlockQuote) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in blockQuote.children {
            var quoteAttributes: [NSAttributedString.Key: Any] = [:]
            
            let quoteParagraphStyle = NSMutableParagraphStyle()
            
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(blockQuote.quoteDepth))
            
            quoteParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: leftMarginOffset)]
            
            quoteParagraphStyle.headIndent = leftMarginOffset
            
            quoteAttributes[.paragraphStyle] = quoteParagraphStyle
            #if os(macOS)
            quoteAttributes[.font] = NSFont.systemFont(ofSize: baseFontSize, weight: .regular)
            #else
            quoteAttributes[.font] = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)
            #endif
            quoteAttributes[.listDepth] = blockQuote.quoteDepth
            
            let quoteAttributedString = visit(child).mutableCopy() as! NSMutableAttributedString
            quoteAttributedString.insert(NSAttributedString(string: "\t", attributes: quoteAttributes), at: 0)
            #if os(macOS)
            quoteAttributedString.addAttribute(.foregroundColor, value: NSColor.systemGray)
            #else
            quoteAttributedString.addAttribute(.foregroundColor, value: UIColor.systemGray)
            #endif
            
            result.append(quoteAttributedString)
        }
        
        if blockQuote.hasSuccessor {
            result.append(.doubleNewline(withFontSize: newLineFontSize))
        }
        
        return result
    }
}

// MARK: - Extensions Land

extension NSMutableAttributedString {
    func applyEmphasis() {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            #if os(macOS)
            guard let font = value as? NSFont else { return }
            let newFont = font.apply(newTraits: .italic)
            #else
            guard let font = value as? UIFont else { return }
            let newFont = font.apply(newTraits: .traitItalic)
            #endif
            
            addAttribute(.font, value: newFont, range: range)
        }
    }
    
    func applyStrong() {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            #if os(macOS)
            guard let font = value as? NSFont else { return }
            let newFont = font.apply(newTraits: .bold)
            #else
            guard let font = value as? UIFont else { return }
            let newFont = font.apply(newTraits: .traitBold)
            #endif
            addAttribute(.font, value: newFont, range: range)
        }
    }
    
    func applyLink(withURL url: URL?) {
        #if os(macOS)
        addAttribute(.foregroundColor, value: NSColor.systemBlue)
        #else
        addAttribute(.foregroundColor, value: UIColor.systemBlue)
        #endif
        
        if let url = url {
            addAttribute(.link, value: url)
        }
    }
    
    func applyBlockquote() {
        #if os(macOS)
        addAttribute(.foregroundColor, value: NSColor.systemGray)
        #else
        addAttribute(.foregroundColor, value: UIColor.systemGray)
        #endif
    }
    
    func applyHeading(withLevel headingLevel: Int) {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            #if os(macOS)
            guard let font = value as? NSFont else { return }
            let newFont = font.apply(newTraits: .bold, newPointSize: 28.0 - CGFloat(headingLevel * 2))
            #else
            guard let font = value as? UIFont else { return }
            let newFont = font.apply(newTraits: .traitBold, newPointSize: 28.0 - CGFloat(headingLevel * 2))
            #endif
            
            addAttribute(.font, value: newFont, range: range)
        }
    }
    
    func applyStrikethrough() {
        addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
    }
}


#if os(macOS)
extension NSFont {
    func apply(newTraits: NSFontDescriptor.SymbolicTraits, newPointSize: CGFloat? = nil) -> NSFont {
        var existingTraits = fontDescriptor.symbolicTraits
        existingTraits.insert(newTraits)
        let newFontDescriptor = fontDescriptor.withSymbolicTraits(existingTraits)
        return NSFont(descriptor: newFontDescriptor, size: newPointSize ?? pointSize) ?? self
    }
}

#else
extension UIFont {
    func apply(newTraits: UIFontDescriptor.SymbolicTraits, newPointSize: CGFloat? = nil) -> UIFont {
        var existingTraits = fontDescriptor.symbolicTraits
        existingTraits.insert(newTraits)
        
        guard let newFontDescriptor = fontDescriptor.withSymbolicTraits(existingTraits) else { return self }
        return UIFont(descriptor: newFontDescriptor, size: newPointSize ?? pointSize)
    }
}
#endif



extension ListItemContainer {
    /// Depth of the list if nested within others. Index starts at 0.
    var listDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension BlockQuote {
    /// Depth of the quote if nested within others. Index starts at 0.
    var quoteDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is BlockQuote {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension NSAttributedString.Key {
    static let listDepth = NSAttributedString.Key("ListDepth")
    static let quoteDepth = NSAttributedString.Key("QuoteDepth")
}

extension NSMutableAttributedString {
    func addAttribute(_ name: NSAttributedString.Key, value: Any) {
        addAttribute(name, value: value, range: NSRange(location: 0, length: length))
    }
    
    func addAttributes(_ attrs: [NSAttributedString.Key : Any]) {
        addAttributes(attrs, range: NSRange(location: 0, length: length))
    }
}

extension Markup {
    /// Returns true if this element has sibling elements after it.
    var hasSuccessor: Bool {
        guard let childCount = parent?.childCount else { return false }
        return indexInParent < childCount - 1
    }
    
    var isContainedInList: Bool {
        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                return true
            }

            currentElement = currentElement?.parent
        }
        
        return false
    }
}

extension NSAttributedString {
    static func singleNewline(withFontSize fontSize: CGFloat) -> NSAttributedString {
        #if os(macOS)
        NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .regular)])
        #else
        NSAttributedString(string: "\n", attributes: [.font: UIFont.systemFont(ofSize: fontSize, weight: .regular)])
        #endif
    }
    
    static func doubleNewline(withFontSize fontSize: CGFloat) -> NSAttributedString {
        #if os(macOS)
        NSAttributedString(string: "\n\n", attributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .regular)])
        #else
        NSAttributedString(string: "\n\n", attributes: [.font: UIFont.systemFont(ofSize: fontSize, weight: .regular)])
        #endif
    }
}


