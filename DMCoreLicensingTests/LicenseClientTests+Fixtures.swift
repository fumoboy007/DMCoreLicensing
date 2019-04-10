// MIT License
//
// Copyright © 2019 Darren Mo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@testable import DMCoreLicensing

import Foundation
import Security

import Hippolyte

extension LicenseClientTests {
   // MARK: - Shared Data

   private static let privateKey: SecKey = {
      let keyAttributes: [CFString: Any] = [
         kSecAttrKeyType: kSecAttrKeyTypeRSA,
         kSecAttrKeySizeInBits: 4096
      ]
      return SecKeyCreateRandomKey(keyAttributes as CFDictionary, nil)!
   }()
   static let publicKey = SecKeyCopyPublicKey(privateKey)!

   static let deviceUUID = SystemInformation.shared.hardwareUUID!
   static let extraInfo = Data([1, 2, 3])

   static let expirationDate = Date.distantFuture
   static let licenseKey = UUID().uuidString

   static let trialActivationEndpoint = URL(string: "https://api.example.com/v1/activate_trial")!
   static let purchaseActivationEndpoint = URL(string: "https://api.example.com/v1/activate_purchase")!

   // MARK: - Specific License Info

   static func makeValidTrialLicenseInfo() -> TrialLicenseInfo {
      var trialLicenseInfo = TrialLicenseInfo()
      trialLicenseInfo.expirationTimestampInSec = Int64(expirationDate.timeIntervalSince1970)

      return trialLicenseInfo
   }

   static func makeValidPurchasedLicenseInfo() -> PurchasedLicenseInfo {
      var purchasedLicenseInfo = PurchasedLicenseInfo()
      purchasedLicenseInfo.licenseKey = licenseKey

      return purchasedLicenseInfo
   }

   // MARK: - License Info

   private static func makeValidLicenseInfo(for specificLicenseInfo: LicenseInfo.OneOf_SpecificInfo) -> LicenseInfo {
      var licenseInfo = LicenseInfo()
      licenseInfo.deviceUuid = deviceUUID.data
      licenseInfo.specificInfo = specificLicenseInfo
      licenseInfo.extraInfo = extraInfo

      return licenseInfo
   }

   static func makeValidLicenseInfoForTrial() -> LicenseInfo {
      return makeValidLicenseInfo(for: .trial(makeValidTrialLicenseInfo()))
   }

   static func makeValidLicenseInfoForPurchase() -> LicenseInfo {
      return makeValidLicenseInfo(for: .purchased(makeValidPurchasedLicenseInfo()))
   }

   static func makeLicenseInfoForDifferentDevice() -> LicenseInfo {
      var licenseInfo = makeValidLicenseInfoForTrial()
      licenseInfo.deviceUuid = UUID().data

      return licenseInfo
   }

   static func makeLicenseInfoWithMissingData() -> LicenseInfo {
      var licenseInfo = makeValidLicenseInfoForTrial()
      licenseInfo.specificInfo = nil

      return licenseInfo
   }

   // MARK: - Signed Bundle

   static func makeValidSignedBundle(for licenseInfo: LicenseInfo) -> SignedBundle {
      let licenseInfoData = try! licenseInfo.serializedData()

      let signature = SecKeyCreateSignature(privateKey,
                                            .rsaSignatureMessagePSSSHA512,
                                            licenseInfoData as CFData,
                                            nil)! as Data

      var signedBundle = SignedBundle()
      signedBundle.keyType = .rsa4096
      signedBundle.publicKey = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data
      signedBundle.signatureAlgorithm = .rsaPssSha512
      signedBundle.signature = signature
      signedBundle.signedMessage = licenseInfoData

      return signedBundle
   }

   static func makeValidSignedBundleForTrial() -> SignedBundle {
      return makeValidSignedBundle(for: makeValidLicenseInfoForTrial())
   }

   static func makeValidSignedBundleForPurchase() -> SignedBundle {
      return makeValidSignedBundle(for: makeValidLicenseInfoForPurchase())
   }

   static func makeMalformedSignedBundleData() -> Data {
      return Data([1, 2, 3])
   }

   static func makeSignedBundleWithUnsupportedKeyType() -> SignedBundle {
      var signedBundle = makeValidSignedBundleForTrial()
      signedBundle.keyType = .UNRECOGNIZED(-1)

      return signedBundle
   }

   static func makeSignedBundleWithInvalidPublicKey() -> SignedBundle {
      var signedBundle = makeValidSignedBundleForTrial()
      signedBundle.publicKey = Data([1, 2, 3])

      return signedBundle
   }

   static func makeSignedBundleWithUnknownPublicKey() -> SignedBundle {
      var signedBundle = makeValidSignedBundleForTrial()
      signedBundle.publicKey = Data(base64Encoded: """
      MIICCgKCAgEA2UAYyhMMcebXu3fvNjYGleIxRIY0hlKf/25Uaw1hhlDtOS50nVzy
      ecLvQQkmdM7Q13hWBfXgJbvMmTyCwKCNA09Sgw+KvS4dw2FSDadVvfz2npg60gNH
      g8BxFM1MBfkQcLs+4TJyse1uUpQE3lTCq3rcdL+BUULUZzvn9UZGwLsjekanpRMn
      /VWvtTizlaLpVYXs71yy+zBSgf6NHYGTGwayggCk4h1YQoxWtYgmKckMldr9dXe3
      NSOLo8pfmbD73p/HTZ3Gw3r7I6isOEZCVxZU8f//1afoBs4fPvvrv7stqbcYGAXb
      6uSGeSY73RJwuBaDaZf0V3/W248cVkF+aTt/QP7YYfSoWIlQgr0yVSw6aJbtYoVu
      24Taal3aouWrpeJEbwnX+fz+FFmjj0eeX0Eb9jsVxtBzAI95BJxIXuWTpRzJQ4TK
      MwK0uAyDyRuwSuh0Xi/q1J78ffTGxuKsRlTicnFKksn1ahxV20Iq/Msm9+p1FXmS
      M//DlEEtkjA5wqkoOVGU5zfgMjyc4DTDcJod33Opbfl4jI30WBLZp5jTt9zYuoD7
      O3JGajpiIoQlpJqVD9lUMPfk29nrFhsPKm3Qj4i3oWEXpOq9HMMMs6UhRMLK8cXY
      /vXDCwR/BRuzcnvz+2eAtCYuZ7SOJ7NlF9aETZ1o52I1RtBjCeXYDrcCAwEAAQ==
      """, options: .ignoreUnknownCharacters)!

      return signedBundle
   }

   static func makeSignedBundleWithUnsupportedSignatureAlgorithm() -> SignedBundle {
      var signedBundle = makeValidSignedBundleForTrial()
      signedBundle.signatureAlgorithm = .UNRECOGNIZED(-1)

      return signedBundle
   }

   static func makeSignedBundleWithInvalidSignature() -> SignedBundle {
      var signedBundle = makeValidSignedBundleForTrial()
      signedBundle.signature = Data([1, 2, 3])

      return signedBundle
   }

   // MARK: - Server Response

   private static func makeActivationResponse(with signedBundle: SignedBundle?,
                                              activationError: String?) -> StubResponse {
      return makeActivationResponse(withSignedBundleData: try! signedBundle?.serializedData(),
                                    activationError: activationError)
   }

   private static func makeActivationResponse(withSignedBundleData signedBundleData: Data?,
                                              activationError: String?) -> StubResponse {
      var responseBodyComponents = [String]()
      if let signedBundleData = signedBundleData {
         responseBodyComponents.append("""
            "signed_license": "\(signedBundleData.base64EncodedString())"
         """)
      }
      if let activationError = activationError {
         responseBodyComponents.append("""
            "activation_error": "\(activationError)"
         """)
      }

      let responseBody = "{\n" + responseBodyComponents.joined(separator: ",\n") + "\n}"

      return
         StubResponse.Builder()
            .stubResponse(withStatusCode: 200)
            .addBody(responseBody.data(using: .utf8)!)
            .build()
   }

   static func makeValidTrialActivationResponse() -> StubResponse {
      let signedBundle = makeValidSignedBundleForTrial()
      return makeActivationResponse(with: signedBundle, activationError: nil)
   }

   static func makeValidTrialActivationResponseWithPurchasedLicense() -> StubResponse {
      let signedBundle = makeValidSignedBundleForPurchase()
      return makeActivationResponse(with: signedBundle, activationError: nil)
   }

   static func makeValidPurchaseActivationResponse() -> StubResponse {
      let signedBundle = makeValidSignedBundleForPurchase()
      return makeActivationResponse(with: signedBundle, activationError: nil)
   }

   static func makeNetworkFailureResponse() -> StubResponse {
      let error = NSError(domain: NSURLErrorDomain,
                          code: NSURLErrorNetworkConnectionLost,
                          userInfo: nil)
      return
         StubResponse.Builder()
            .stubResponse(withError: error)
            .build()
   }

   static func makeServerRejectionResponse() -> StubResponse {
      return
         StubResponse.Builder()
            .stubResponse(withStatusCode: 400)
            .build()
   }

   static func makeMalformedServerResponse() -> StubResponse {
      return
         StubResponse.Builder()
            .stubResponse(withStatusCode: 200)
            .addBody(Data([1, 2, 3]))
            .build()
   }

   static func makePurchaseActivationResponseWithMismatchedLicenseType() -> StubResponse {
      let signedBundle = makeValidSignedBundleForTrial()
      return makeActivationResponse(with: signedBundle, activationError: nil)
   }

   static func makePurchaseActivationResponseWithMissingData() -> StubResponse {
      return makeActivationResponse(with: nil, activationError: nil)
   }

   static func makePurchaseActivationResponseWithLicenseKeyNotFoundError() -> StubResponse {
      return makeActivationResponse(with: nil, activationError: "license_key_not_found")
   }

   static func makePurchaseActivationResponseWithDeviceQuotaExceededError() -> StubResponse {
      return makeActivationResponse(with: nil, activationError: "device_quota_exceeded")
   }

   static func makePurchaseActivationResponseWithUnrecognizedError() -> StubResponse {
      return makeActivationResponse(with: nil, activationError: "my_error")
   }

   static func makeActivationResponseWithInvalidLicense() -> StubResponse {
      return makeActivationResponse(withSignedBundleData: Data([1, 2, 3]), activationError: nil)
   }
}
