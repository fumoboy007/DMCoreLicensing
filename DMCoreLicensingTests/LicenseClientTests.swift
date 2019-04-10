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
import XCTest

import Hippolyte

class LicenseClientTests: XCTestCase {
   // MARK: - License Client

   private var licenseClient: LicenseClient!

   // MARK: - Set Up/Tear Down

   override func setUp() {
      super.setUp()

      licenseClient = LicenseClient(knownPublicKeys: [LicenseClientTests.publicKey])
   }

   override func tearDown() {
      Hippolyte.shared.stop()

      deleteStoredLicense()

      super.tearDown()
   }

   // MARK: - Storing/Deleting the License

   private func storeLicense(signedBundle: SignedBundle) {
      storeLicense(signedBundleData: try! signedBundle.serializedData())
   }

   private func storeLicense(signedBundleData: Data) {
      UserDefaults.standard.set(signedBundleData,
                                forKey: UserDefaultsKeys.license)
   }

   private func deleteStoredLicense() {
      UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.license)
   }

   // MARK: - Stubbing Responses

   private static func stubResponse(toEndpoint endpointURL: URL, with stubbedResponse: StubResponse) {
      let stubbedRequest =
         StubRequest.Builder()
            .stubRequest(withMethod: .POST, url: endpointURL)
            .addResponse(stubbedResponse)
            .build()

      Hippolyte.shared.add(stubbedRequest: stubbedRequest)
   }

   // MARK: - License Validation

   private func testInvalidLicense(signedBundle: SignedBundle,
                                   errorHandler: (LicenseClient.LicenseValidationError) -> Void) {
      storeLicense(signedBundle: signedBundle)
      testInvalidLicense(errorHandler: errorHandler)
   }

   private func testInvalidLicense(signedBundleData: Data,
                                   errorHandler: (LicenseClient.LicenseValidationError) -> Void) {
      storeLicense(signedBundleData: signedBundleData)
      testInvalidLicense(errorHandler: errorHandler)
   }

   private func testInvalidLicense(errorHandler: (LicenseClient.LicenseValidationError) -> Void) {
      XCTAssertThrowsError(try licenseClient.loadLicense()) { error in
         guard let licenseLoadError = error as? LicenseClient.LicenseLoadError else {
            XCTFail()
            return
         }

         switch licenseLoadError {
         case .licenseValidationFailure(let licenseValidationError):
            errorHandler(licenseValidationError)
         }
      }
   }

   func testMalformedSignedBundleData() {
      testInvalidLicense(signedBundleData: LicenseClientTests.makeMalformedSignedBundleData()) { error in
         switch error {
         case .deserializationFailure(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnsupportedKeyType() {
      testInvalidLicense(signedBundle: LicenseClientTests.makeSignedBundleWithUnsupportedKeyType()) { error in
         switch error {
         case .unsupportedKeyType(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithInvalidPublicKey() {
      testInvalidLicense(signedBundle: LicenseClientTests.makeSignedBundleWithInvalidPublicKey()) { error in
         switch error {
         case .invalidPublicKey(_, _):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnknownPublicKey() {
      testInvalidLicense(signedBundle: LicenseClientTests.makeSignedBundleWithUnknownPublicKey()) { error in
         switch error {
         case .unknownPublicKey(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnsupportedSignatureAlgorithm() {
      testInvalidLicense(signedBundle: LicenseClientTests.makeSignedBundleWithUnsupportedSignatureAlgorithm()) { error in
         switch error {
         case .unsupportedSignatureAlgorithm(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithInvalidSignature() {
      testInvalidLicense(signedBundle: LicenseClientTests.makeSignedBundleWithInvalidSignature()) { error in
         switch error {
         case .invalidSignature(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testLicenseInfoForDifferentDevice() {
      let signedBundle = LicenseClientTests.makeValidSignedBundle(for: LicenseClientTests.makeLicenseInfoForDifferentDevice())
      testInvalidLicense(signedBundle: signedBundle) { error in
         switch error {
         case .mismatchedDevice:
            break

         default:
            XCTFail()
         }
      }
   }

   func testLicenseInfoWithMissingData() {
      let signedBundle = LicenseClientTests.makeValidSignedBundle(for: LicenseClientTests.makeLicenseInfoWithMissingData())
      testInvalidLicense(signedBundle: signedBundle) { error in
         switch error {
         case .missingData:
            break

         default:
            XCTFail()
         }
      }
   }

   // MARK: - Loading the License

   func testLoadNonExistentLicense() throws {
      let license = try licenseClient.loadLicense()
      XCTAssertNil(license)
   }

   func testLoadTrialLicense() throws {
      storeLicense(signedBundle: LicenseClientTests.makeValidSignedBundleForTrial())

      let license = try licenseClient.loadLicense()
      XCTAssertNotNil(license)

      switch license! {
      case .trial(let trialLicense):
         XCTAssertEqual(trialLicense.expirationDate, LicenseClientTests.expirationDate)
         XCTAssertEqual(trialLicense.extraInfo, LicenseClientTests.extraInfo)

      default:
         XCTFail()
      }
   }

   func testLoadPurchasedLicense() throws {
      storeLicense(signedBundle: LicenseClientTests.makeValidSignedBundleForPurchase())

      let license = try licenseClient.loadLicense()
      XCTAssertNotNil(license)

      switch license! {
      case .purchased(let purchasedLicense):
         XCTAssertEqual(purchasedLicense.licenseKey, LicenseClientTests.licenseKey)
         XCTAssertEqual(purchasedLicense.extraInfo, LicenseClientTests.extraInfo)

      default:
         XCTFail()
      }
   }

   // MARK: - Activation

   private func runTrialActivation(with stubbedResponse: StubResponse,
                                   completionHandler: @escaping (Result<License, LicenseClient.ActivationError>) -> Void) {
      LicenseClientTests.stubResponse(toEndpoint: LicenseClientTests.trialActivationEndpoint,
                                       with: stubbedResponse)
      Hippolyte.shared.start()

      let expectation = self.expectation(description: "Completion handler was called.")
      licenseClient.activateTrial(usingEndpoint: LicenseClientTests.trialActivationEndpoint, runningCompletionHandlerOn: DispatchQueue.global()) { result in
         completionHandler(result)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 2)
   }

   private func runPurchaseActivation(with stubbedResponse: StubResponse,
                                      completionHandler: @escaping (Result<PurchasedLicense, LicenseClient.ActivationError>) -> Void) {
      LicenseClientTests.stubResponse(toEndpoint: LicenseClientTests.purchaseActivationEndpoint,
                                       with: stubbedResponse)
      Hippolyte.shared.start()

      let expectation = self.expectation(description: "Completion handler was called.")
      licenseClient.activatePurchase(forLicenseKey: LicenseClientTests.licenseKey, usingEndpoint: LicenseClientTests.purchaseActivationEndpoint, runningCompletionHandlerOn: DispatchQueue.global()) { result in
         completionHandler(result)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 2)
   }

   func testValidTrialActivationResponse() {
      runTrialActivation(with: LicenseClientTests.makeValidTrialActivationResponse()) { result in
         switch result {
         case .success(.trial(let trialLicense)):
            XCTAssertEqual(trialLicense.expirationDate, LicenseClientTests.expirationDate)
            XCTAssertEqual(trialLicense.extraInfo, LicenseClientTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testValidTrialActivationResponseWithPurchasedLicense() {
      runTrialActivation(with: LicenseClientTests.makeValidTrialActivationResponseWithPurchasedLicense()) { result in
         switch result {
         case .success(.purchased(let purchasedLicense)):
            XCTAssertEqual(purchasedLicense.licenseKey, LicenseClientTests.licenseKey)
            XCTAssertEqual(purchasedLicense.extraInfo, LicenseClientTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testValidPurchaseActivationResponse() {
      runPurchaseActivation(with: LicenseClientTests.makeValidPurchaseActivationResponse()) { result in
         switch result {
         case .success(let purchasedLicense):
            XCTAssertEqual(purchasedLicense.licenseKey, LicenseClientTests.licenseKey)
            XCTAssertEqual(purchasedLicense.extraInfo, LicenseClientTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testNetworkFailure() {
      runTrialActivation(with: LicenseClientTests.makeNetworkFailureResponse()) { result in
         switch result {
         case .failure(.networkFailure(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testServerRejection() {
      runTrialActivation(with: LicenseClientTests.makeServerRejectionResponse()) { result in
         switch result {
         case .failure(.serverRejectedRequest(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testMalformedServerResponse() {
      runTrialActivation(with: LicenseClientTests.makeMalformedServerResponse()) { result in
         switch result {
         case .failure(.invalidServerResponse(.deserializationFailure(_))):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithMismatchedLicenseType() {
      runPurchaseActivation(with: LicenseClientTests.makePurchaseActivationResponseWithMismatchedLicenseType()) { result in
         switch result {
         case .failure(.invalidServerResponse(.mismatchedLicenseType)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithMissingData() {
      runPurchaseActivation(with: LicenseClientTests.makePurchaseActivationResponseWithMissingData()) { result in
         switch result {
         case .failure(.invalidServerResponse(.missingData)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithLicenseKeyNotFoundError() {
      runPurchaseActivation(with: LicenseClientTests.makePurchaseActivationResponseWithLicenseKeyNotFoundError()) { result in
         switch result {
         case .failure(.licenseKeyNotFound):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithDeviceQuotaExceededError() {
      runPurchaseActivation(with: LicenseClientTests.makePurchaseActivationResponseWithDeviceQuotaExceededError()) { result in
         switch result {
         case .failure(.deviceQuotaExceeded):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithUnrecognizedError() {
      runPurchaseActivation(with: LicenseClientTests.makePurchaseActivationResponseWithUnrecognizedError()) { result in
         switch result {
         case .failure(.unrecognizedServerError(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testActivationResponseWithInvalidLicense() {
      runTrialActivation(with: LicenseClientTests.makeActivationResponseWithInvalidLicense()) { result in
         switch result {
         case .failure(.licenseValidationFailure(_)):
            break

         default:
            XCTFail()
         }
      }
   }
}
