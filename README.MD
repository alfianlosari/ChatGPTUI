# ChatGPT UI For SwiftUI

![Alt text](https://i.ibb.co.com/QFPj8kg/Screenshot-2024-05-19-at-21-33-55.png "image")

Simple and extensible Drop-in ChatGPT UI Solution for Apple Platforms.

## Supported Platforms

- iOS 17
- macOS 14
- visionOS 1.x

## Installation

### Swift Package Manager
- File > Swift Packages > Add Package Dependency
- Add https://github.com/alfianlosari/ChatGPTUI.git

### Import
Import to your project source file.

```swift
import ChatGPTUI
```

## Requirement

Register for API key from [OpenAI](https://openai.com/api). Initialize with api key

## Usage

### Text Chat View

Simply initialize passing the `apiKey` in SwiftUI View

```swift
var body: some View {
    NavigationStack {
        TextChatView(apiKey: apiKey)
            .navigationTitle("XCA ChatGPTUI")
    }
}
```

Pass optional imageName from asset or remote image URL to render as sender and bot images

```swift
var body: some View {
    NavigationStack {
        TextChatView(
            senderImage: senderImage,
            botImage: botImage,
            apiKey: apiKey)
            .navigationTitle("XCA ChatGPTUI")
    }
}
```

### Voice Chat View

Coming Soon!
