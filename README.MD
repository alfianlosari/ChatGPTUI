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

Pass these optional params for customization:
- `senderImage` and `botImage` from asset or remote image URL to render as sender and bot images.
- `model` ChatGPTModel enum (gpt-4o, gpt-4turbo, gpt-3.5, etc)
- `systemText` system text prompt used by ChatGPT.
- `temperature` Temperature used by ChatGPT for response.

```swift
var body: some View {
    NavigationStack {
        TextChatView(
            senderImage: senderImage,
            botImage: botImage,
            model: .gpt_hyphen_4o,
            systemText: "You're master of Swift Programming",
            temperature: 1.0,
            apiKey: apiKey)
            .navigationTitle("XCA ChatGPTUI")
    }
}
```

Make sure you are in tier that eligible for gpt4 models access. You can learn more from here [How can I access GPT-4, GPT-4 Turbo and GPT-4o?](https://help.openai.com/en/articles/7102672-how-can-i-access-gpt-4-gpt-4-turbo-and-gpt-4o). 

### Voice Chat View

Coming Soon!
