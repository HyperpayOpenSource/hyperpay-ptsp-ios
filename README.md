# Hyperpay PTSP SDK - iOS Integration Guide

## Overview

The Hyperpay PTSP SDK is a complete payment processing solution for iOS applications. It provides seamless integration for handling payment flows with WebView support, allowing users to complete payments and receive real-time callbacks.

✅ **iOS 14.0+** - Supports modern iOS versions

---

## Prerequisites

Before integrating HyperpayPtspSdk, you must have:

1. **Flutter installed** in your iOS project

   - The SDK is built on Flutter and requires Flutter to be present
   - If not already using Flutter, follow [Flutter iOS integration guide](https://docs.flutter.dev/add-to-app/ios/project-setup)

2. **CocoaPods** installed

   ```bash
   sudo gem install cocoapods
   ```

3. **Xcode 14.0+** with iOS 14.0+ support

---

## Installation

### Option 1: CocoaPods (Recommended)

1. **Add to your Podfile:**

```ruby
pod 'HyperpayPtspSdk'
pod 'Flutter'  # Required dependency
```

2. **Install dependencies:**

```bash
pod install
```

3. **Update your Xcode project:**

```bash
open YourApp.xcworkspace
```

⚠️ **IMPORTANT**: Always use `.xcworkspace` (not `.xcodeproj`) after running `pod install`

### Option 2: Manual Framework (Embed & Sign Approach)

1. Download `HyperpayPtspSdk.xcframework` from the [releases page](https://github.com/HyperpayOpenSource/hyperpay-ptsp-ios/releases)

2. In Xcode, drag the framework into your project's **Frameworks** folder

3. Select your project → **Build Phases** → **Link Binary With Libraries**

   - Click **+** and add: `HyperpayPtspSdk.framework`, `Flutter.framework`, and any plugins
   - For each framework, click the row and set **Embed** dropdown to **"Embed & Sign"**

4. Configure Build Settings for your target:

   ```
   BRIDGING_HEADER = "YourApp/YourApp-Bridging-Header.h"
   FRAMEWORK_SEARCH_PATHS = "$(SRCROOT)/Frameworks"
   SWIFT_MODULE_SEARCH_PATHS = "$(SRCROOT)/Frameworks"
   CODE_SIGN_STYLE = Automatic
   ```

5. Add a **Bridging Header** (see [Step 0](#step-0-create-bridging-header-for-manual-integration))

---

## Setup Steps

### Step 0: Create Bridging Header (For Manual Integration)

**Purpose:** Allow Swift code to import Objective-C/C headers from Flutter framework.

Create a new file `YourApp-Bridging-Header.h`:

```objc
//
//  YourApp-Bridging-Header.h
//

#ifndef YourApp_Bridging_Header_h
#define YourApp_Bridging_Header_h

// Import Flutter framework
#import <Flutter/Flutter.h>

@class FlutterViewController;
@class FlutterMethodChannel;

#endif
```

In Xcode Build Settings, set:

- **BRIDGING_HEADER** = `YourApp/YourApp-Bridging-Header.h`

⚠️ **Note:** CocoaPods integration handles this automatically. Only needed for manual framework integration.

---

### Step 1: Initialize Flutter Engine in AppDelegate

**Purpose:** Set up the Flutter engine when your app launches to enable communication between iOS and the payment SDK.

```swift
import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var flutterEngine: FlutterEngine?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Create and start Flutter engine
        flutterEngine = FlutterEngine(name: "ptsp_engine")
        flutterEngine?.run()

        return true
    }
}
```

**What happens:**

- Flutter engine loads the Dart code
- Creates communication channel for iOS ↔️ Dart
- Ready to handle payment operations

---

### Step 2: Setup Flutter MethodChannel

**Purpose:** Create a communication bridge with the Flutter SDK from your ViewController.

```swift
import UIKit
import Flutter

class PaymentViewController: UIViewController {
    private var channel: FlutterMethodChannel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFlutterChannel()
    }

    private func setupFlutterChannel() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let engine = appDelegate.flutterEngine else {
            print("❌ Failed to get Flutter engine")
            return
        }

        channel = FlutterMethodChannel(
            name: "com.hyperpay.ptsp/sdk",
            binaryMessenger: engine.binaryMessenger
        )

        print("✅ MethodChannel initialized")
    }
}
```

**Key points:**

- Channel name: `com.hyperpay.ptsp/sdk`
- Access the engine from AppDelegate
- Channel is ready for payment operations

---

### Execute Payment Operations

Process payment in sequence using the initialized MethodChannel:

#### Step 1 - Initialize SDK

Initialize the SDK with your API credentials. **The API key is stored and reused for all subsequent calls—you only need to pass it once.**

```swift
guard let channel = channel else { return }

channel.invokeMethod("initialize", arguments: [
    "apiKey": "your_api_key_here",
    "environment": "staging"  // or "production"
]) { result in
    if result is FlutterError {
        print("❌ Initialize failed")
        return
    }
    print("✅ SDK initialized")
}
```

**Parameters:**

- `apiKey`: Your Hyperpay merchant API key (stored internally, reused for all operations)
- `environment`: Deployment environment ("staging" or "production")

---

#### Step 2 - Set Payment Token

Set the payment token received from your backend:

```swift
channel.invokeMethod("setToken", arguments: [
    "token": "payment_token_from_your_backend"
]) { result in
    if result is FlutterError {
        print("❌ Set token failed")
        return
    }
    print("✅ Token set")
}
```

**Parameters:**

- `token`: Payment token obtained from [Getting Payment Token](#getting-api-key--token)

---

**Payemnt Cycle Flow:**

```
Set Token → Process Payment → Callback
```

---

### Verify Payment Status via Status API

Note: The callback does not return the final payment status.
It only confirms that the transaction request was successfully processed by the payment gateway.

After the user completes the payment flow, you must verify the actual payment result from your backend by calling the
[`Status API`](https://hyperpayptsp.docs.apiary.io/#) to confirm that the payment was completed successfully.

---

## Getting API Key & Token

### 1. API Key

Your merchant API key from Hyperpay:

- **How to get it**: Contact Hyperpay support or visit your merchant dashboard
- **Used in**: `initialize()` method
- **Stored**: The API key is securely stored internally after initialization and reused for all payment operations—**you only pass it once**
- **Reference**: [`Hyperpay PTSP Documentation`](https://hyperpayptsp.docs.apiary.io/#)

### 2. Payment Token

Token generated from your backend server:

- **Your backend calls**: `GET /v1/payment-link`
- **Your backend receives**: Payment token (string)
- **Pass to SDK**: Use in `setToken()` method
- **Reference**: [`Hyperpay PTSP Documentation`](https://hyperpayptsp.docs.apiary.io/#)

---

## Troubleshooting

| Issue                       | Solution                                                         |
| --------------------------- | ---------------------------------------------------------------- |
| **FlutterEngine is nil**    | Check AppDelegate setup, ensure `flutterEngine?.run()` is called |
| **MethodChannel errors**    | Verify channel name: `com.hyperpay.ptsp/sdk`                     |
| **WebView won't load**      | Check payment URL is valid and internet is enabled               |
| **Payment never completes** | Check network connectivity and API credentials                   |
| **CocoaPods fails**         | Run `pod repo update` then `pod install --repo-update`           |

---

## Support

For issues or questions:

- Email: technical@hyperpay.com
- GitHub Issues: https://github.com/HyperpayOpenSource/hyperpay-ptsp-ios/issues

---

## License

MIT License - See LICENSE file for details
