# Hyperpay PTSP SDK - iOS Integration Guide

## Overview

The Hyperpay PTSP SDK is a complete payment processing solution for iOS applications. It provides seamless integration for handling payment flows with WebView support, allowing users to complete payments and receive real-time callbacks.

## Features

✅ **Easy Integration** - Simple method channel communication  
✅ **WebView Support** - Built-in payment page display with WKWebView  
✅ **Callback Handling** - Get notified when payment completes  
✅ **Error Handling** - Comprehensive logging and error messages  
✅ **iOS 14.0+** - Supports modern iOS versions  
✅ **Swift Ready** - Fully compatible with Swift 5.0+

---

## Installation

### Option 1: CocoaPods (Recommended)

1. **Add to your Podfile:**

```ruby
pod 'HyperpayPtspSdk', '~> 1.0.0'
```

2. **Install dependencies:**

```bash
pod install
```

3. **Update your Xcode project:**

```bash
open YourApp.xcworkspace
```

### Option 2: Manual Framework

1. Download `HyperpayPtspSdk.xcframework`
2. In Xcode:
   - Select your project
   - Go to Build Phases → Link Binary With Libraries
   - Add `HyperpayPtspSdk.xcframework`

---

## Setup Steps

### Step 1: Initialize Flutter Engine in AppDelegate

Set up the Flutter engine when your app launches:

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

### Step 2: Setup MethodChannel in Your View Controller

Create a method channel to communicate with Flutter:

```swift
import UIKit

class PaymentViewController: UIViewController {
    private var channel: FlutterMethodChannel?
    private var flutterEngine: FlutterEngine?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFlutter()
    }

    private func setupFlutter() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let engine = appDelegate.flutterEngine else {
            print("❌ Failed to get Flutter engine")
            return
        }

        flutterEngine = engine
        channel = FlutterMethodChannel(
            name: "com.hyperpay.ptsp/sdk",
            binaryMessenger: engine.binaryMessenger
        )

        // Listen for payment results from Flutter
        channel?.setMethodCallHandler { [weak self] call, result in
            if call.method == "onPaymentResult" {
                let args = call.arguments as? [String: Any] ?? [:]
                self?.handlePaymentResult(args)
                result(nil)
            }
        }

        print("✅ MethodChannel initialized")
    }

    private func handlePaymentResult(_ result: [String: Any]) {
        let status = result["status"] as? String ?? "unknown"
        let transactionId = result["transactionId"] as? String ?? "N/A"
        print("📲 Payment Result: \(status) - \(transactionId)")
    }
}
```

**Key points:**

- Channel name must be: `com.hyperpay.ptsp/sdk`
- Listen for `onPaymentResult` callback
- Store reference to engine

---

### Step 3: Call SDK Methods in Sequence

To process a payment, follow this sequence:

**Step 3A - Initialize SDK:**

```swift
guard let channel = channel else { return }

channel.invokeMethod("initialize", arguments: [
    "apiKey": "your_api_key_here",
    "baseUrl": "env"  // e.g., "staging" or "production"
]) { result in
    if result is FlutterError {
        print("❌ Initialize failed")
        return
    }
    print("✅ SDK initialized")
    // Continue to Step 3B
}
```

**Step 3B - Set Payment Token:**

```swift
channel.invokeMethod("setToken", arguments: [
    "token": "payment_token_from_your_backend"
]) { result in
    if result is FlutterError {
        print("❌ Set token failed")
        return
    }
    print("✅ Token set")
    // Continue to Step 3C
}
```

**Step 3C - Get Payment URL:**

```swift
channel.invokeMethod("getPaymentUrl", arguments: nil) { result in
    guard let paymentUrl = result as? String else {
        print("❌ Failed to get payment URL")
        return
    }

    print("✅ Got payment URL: \(paymentUrl)")
    // Proceed to Step 4
    self.openPaymentWebView(url: paymentUrl)
}
```

**Flow:**

```
Initialize → Set Token → Get Payment URL → Open WebView → User Pays → Callback
```

---

### Step 4: Verify Payment Status via Status API

After the user completes the payment flow and the WebView closes, verify the payment status using the **Status API** from your backend server to confirm payment completion:

```
Verify payment status server-to-server using the Status API endpoint:

GET https://ptsp-stg.hyperpay.com/v1/status/{merchant-reference}
Header: Authorization: Bearer {YOUR_API_KEY}
```

**Why:** Confirms the transaction was processed successfully on the payment gateway.

---

## Getting API Key & Token

### 1. API Key

Your merchant API key from Hyperpay:

- **Where to get it**: https://dashboard.hyperpay.com/api-keys (will be provided later)
- **Refferance**: `TODO:- `

### 2. Payment Token

Token generated from your backend server:

- **Your backend calls**: `POST https://api.example.com/generate-token`
- **Your backend receives**: Payment token (string)
- **Pass to SDK**: Use in `setToken()` method
- **Example response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
````
- **Refferance**: `TODO:- `

**Contact support:** Email support@hyperpay.com or visit https://docs.hyperpay.com for API key registration and token generation documentation.

---

## API Reference

### Initialize

```swift
channel.invokeMethod("initialize", arguments: [
    "apiKey": String,
    "baseUrl": String
])
```

**Parameters:**

- `apiKey`: Your Hyperpay merchant key
- `baseUrl`: enviroment

**Response:**

- Success: Returns null
- Error: FlutterError

---

### Set Token

```swift
channel.invokeMethod("setToken", arguments: [
    "token": String
])
```

**Parameters:**

- `token`: Payment token from your backend

**Response:**

- Success: Returns null
- Error: FlutterError

---

### Get Payment URL

```swift
channel.invokeMethod("getPaymentUrl", arguments: nil) { result in
    let paymentUrl = result as? String // e.g., "https://hypbill.com/xxxxx"
}
```

**Returns:**

- `String`: Payment page URL to load in WebView

---

### Payment Result Callback

Triggered when payment completes:

```swift
channel.setMethodCallHandler { call, result in
    if call.method == "onPaymentResult" {
        let args = call.arguments as? [String: Any]
        let status = args?["status"] as? String      // "success" or "failed"
        let transactionId = args?["transactionId"] as? String
        let message = args?["message"] as? String

        result(nil)
    }
}
```

---

## Response Examples

### Success

```json
{
  "status": "success",
  "transactionId": "22cd494075342e433091769ad27e666c",
  "message": "Payment completed successfully"
}
```

### Failure

```json
{
  "status": "failed",
  "transactionId": "",
  "message": "Payment was cancelled by user"
}
```

---

## Complete Integration Checklist

- [ ] Add `HyperpayPtspSdk` pod to Podfile
- [ ] Run `pod install`
- [ ] Initialize FlutterEngine in AppDelegate
- [ ] Create MethodChannel in your ViewController
- [ ] Get API key from Hyperpay dashboard
- [ ] Get payment token from your backend
- [ ] Call `initialize()` → `setToken()` → `getPaymentUrl()`
- [ ] Display payment WebView
- [ ] Verify Payment Status via Status API

---

## Troubleshooting

| Issue                       | Solution                                                         |
| --------------------------- | ---------------------------------------------------------------- |
| **FlutterEngine is nil**    | Check AppDelegate setup, ensure `flutterEngine?.run()` is called |
| **MethodChannel errors**    | Verify channel name: `com.hyperpay.ptsp/sdk`                     |
| **WebView won't load**      | Check payment URL is valid and internet is enabled               |
| **Payment never completes** | Verify success/failure URL patterns in `checkPaymentStatus()`    |
| **CocoaPods fails**         | Run `pod repo update` then `pod install --repo-update`           |

---

## Support

For issues or questions:

- Email: support@hyperpay.com
- Documentation: https://docs.hyperpay.com
- GitHub Issues: https://github.com/hyperpay/ptsp-sdk-ios/issues

---

## License

MIT License - See LICENSE file for details
