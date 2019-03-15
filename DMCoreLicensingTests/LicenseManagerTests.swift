//
//  LicenseManagerTests.swift
//  DMCoreLicensingTests
//
//  Created by Darren Mo on 2019-03-11.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

@testable import DMCoreLicensing

import Foundation
import XCTest

import Hippolyte

class LicenseManagerTests: XCTestCase {
   // MARK: - License Manager

   private var licenseManager: LicenseManager!

   // MARK: - Set Up/Tear Down

   override func setUp() {
      super.setUp()

      licenseManager = LicenseManager(knownPublicKeys: [LicenseManagerTests.publicKey])
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
                                   errorHandler: (LicenseManager.LicenseValidationError) -> Void) {
      storeLicense(signedBundle: signedBundle)
      testInvalidLicense(errorHandler: errorHandler)
   }

   private func testInvalidLicense(signedBundleData: Data,
                                   errorHandler: (LicenseManager.LicenseValidationError) -> Void) {
      storeLicense(signedBundleData: signedBundleData)
      testInvalidLicense(errorHandler: errorHandler)
   }

   private func testInvalidLicense(errorHandler: (LicenseManager.LicenseValidationError) -> Void) {
      XCTAssertThrowsError(try licenseManager.loadLicense()) { error in
         guard let licenseLoadError = error as? LicenseManager.LicenseLoadError else {
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
      testInvalidLicense(signedBundleData: LicenseManagerTests.makeMalformedSignedBundleData()) { error in
         switch error {
         case .deserializationFailure(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnsupportedKeyType() {
      testInvalidLicense(signedBundle: LicenseManagerTests.makeSignedBundleWithUnsupportedKeyType()) { error in
         switch error {
         case .unsupportedKeyType(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithInvalidPublicKey() {
      testInvalidLicense(signedBundle: LicenseManagerTests.makeSignedBundleWithInvalidPublicKey()) { error in
         switch error {
         case .invalidPublicKey(_, _):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnknownPublicKey() {
      testInvalidLicense(signedBundle: LicenseManagerTests.makeSignedBundleWithUnknownPublicKey()) { error in
         switch error {
         case .unknownPublicKey(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithUnsupportedSignatureAlgorithm() {
      testInvalidLicense(signedBundle: LicenseManagerTests.makeSignedBundleWithUnsupportedSignatureAlgorithm()) { error in
         switch error {
         case .unsupportedSignatureAlgorithm(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testSignedBundleWithInvalidSignature() {
      testInvalidLicense(signedBundle: LicenseManagerTests.makeSignedBundleWithInvalidSignature()) { error in
         switch error {
         case .invalidSignature(_):
            break

         default:
            XCTFail()
         }
      }
   }

   func testLicenseInfoForDifferentComputer() {
      let signedBundle = LicenseManagerTests.makeValidSignedBundle(for: LicenseManagerTests.makeLicenseInfoForDifferentComputer())
      testInvalidLicense(signedBundle: signedBundle) { error in
         switch error {
         case .mismatchedComputer:
            break

         default:
            XCTFail()
         }
      }
   }

   func testLicenseInfoWithMissingData() {
      let signedBundle = LicenseManagerTests.makeValidSignedBundle(for: LicenseManagerTests.makeLicenseInfoWithMissingData())
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
      let license = try licenseManager.loadLicense()
      XCTAssertNil(license)
   }

   func testLoadTrialLicense() throws {
      storeLicense(signedBundle: LicenseManagerTests.makeValidSignedBundleForTrial())

      let license = try licenseManager.loadLicense()
      XCTAssertNotNil(license)

      switch license! {
      case .trial(let trialLicense):
         XCTAssertEqual(trialLicense.expirationDate, LicenseManagerTests.expirationDate)
         XCTAssertEqual(trialLicense.extraInfo, LicenseManagerTests.extraInfo)

      default:
         XCTFail()
      }
   }

   func testLoadPurchasedLicense() throws {
      storeLicense(signedBundle: LicenseManagerTests.makeValidSignedBundleForPurchase())

      let license = try licenseManager.loadLicense()
      XCTAssertNotNil(license)

      switch license! {
      case .purchased(let purchasedLicense):
         XCTAssertEqual(purchasedLicense.licenseKey, LicenseManagerTests.licenseKey)
         XCTAssertEqual(purchasedLicense.extraInfo, LicenseManagerTests.extraInfo)

      default:
         XCTFail()
      }
   }

   // MARK: - Activation

   private func runTrialActivation(with stubbedResponse: StubResponse,
                                   completionHandler: @escaping (Result<License, LicenseManager.ActivationError>) -> Void) {
      LicenseManagerTests.stubResponse(toEndpoint: LicenseManagerTests.trialActivationEndpoint,
                                       with: stubbedResponse)
      Hippolyte.shared.start()

      let expectation = self.expectation(description: "Completion handler was called.")
      licenseManager.activateTrial(usingEndpoint: LicenseManagerTests.trialActivationEndpoint, runningCompletionHandlerOn: DispatchQueue.global()) { result in
         completionHandler(result)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 2)
   }

   private func runPurchaseActivation(with stubbedResponse: StubResponse,
                                      completionHandler: @escaping (Result<PurchasedLicense, LicenseManager.ActivationError>) -> Void) {
      LicenseManagerTests.stubResponse(toEndpoint: LicenseManagerTests.purchaseActivationEndpoint,
                                       with: stubbedResponse)
      Hippolyte.shared.start()

      let expectation = self.expectation(description: "Completion handler was called.")
      licenseManager.activatePurchase(forLicenseKey: LicenseManagerTests.licenseKey, usingEndpoint: LicenseManagerTests.purchaseActivationEndpoint, runningCompletionHandlerOn: DispatchQueue.global()) { result in
         completionHandler(result)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 2)
   }

   func testValidTrialActivationResponse() {
      runTrialActivation(with: LicenseManagerTests.makeValidTrialActivationResponse()) { result in
         switch result {
         case .success(.trial(let trialLicense)):
            XCTAssertEqual(trialLicense.expirationDate, LicenseManagerTests.expirationDate)
            XCTAssertEqual(trialLicense.extraInfo, LicenseManagerTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testValidTrialActivationResponseWithPurchasedLicense() {
      runTrialActivation(with: LicenseManagerTests.makeValidTrialActivationResponseWithPurchasedLicense()) { result in
         switch result {
         case .success(.purchased(let purchasedLicense)):
            XCTAssertEqual(purchasedLicense.licenseKey, LicenseManagerTests.licenseKey)
            XCTAssertEqual(purchasedLicense.extraInfo, LicenseManagerTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testValidPurchaseActivationResponse() {
      runPurchaseActivation(with: LicenseManagerTests.makeValidPurchaseActivationResponse()) { result in
         switch result {
         case .success(let purchasedLicense):
            XCTAssertEqual(purchasedLicense.licenseKey, LicenseManagerTests.licenseKey)
            XCTAssertEqual(purchasedLicense.extraInfo, LicenseManagerTests.extraInfo)

         default:
            XCTFail()
         }
      }
   }

   func testNetworkFailure() {
      runTrialActivation(with: LicenseManagerTests.makeNetworkFailureResponse()) { result in
         switch result {
         case .failure(.networkFailure(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testServerRejection() {
      runTrialActivation(with: LicenseManagerTests.makeServerRejectionResponse()) { result in
         switch result {
         case .failure(.serverRejectedRequest(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testMalformedServerResponse() {
      runTrialActivation(with: LicenseManagerTests.makeMalformedServerResponse()) { result in
         switch result {
         case .failure(.invalidServerResponse(.deserializationFailure(_))):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithMismatchedLicenseType() {
      runPurchaseActivation(with: LicenseManagerTests.makePurchaseActivationResponseWithMismatchedLicenseType()) { result in
         switch result {
         case .failure(.invalidServerResponse(.mismatchedLicenseType)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithMissingData() {
      runPurchaseActivation(with: LicenseManagerTests.makePurchaseActivationResponseWithMissingData()) { result in
         switch result {
         case .failure(.invalidServerResponse(.missingData)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithLicenseKeyNotFoundError() {
      runPurchaseActivation(with: LicenseManagerTests.makePurchaseActivationResponseWithLicenseKeyNotFoundError()) { result in
         switch result {
         case .failure(.licenseKeyNotFound):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithLicenseQuotaExceededError() {
      runPurchaseActivation(with: LicenseManagerTests.makePurchaseActivationResponseWithLicenseQuotaExceededError()) { result in
         switch result {
         case .failure(.licenseQuotaExceeded):
            break

         default:
            XCTFail()
         }
      }
   }

   func testPurchaseActivationResponseWithUnrecognizedError() {
      runPurchaseActivation(with: LicenseManagerTests.makePurchaseActivationResponseWithUnrecognizedError()) { result in
         switch result {
         case .failure(.unrecognizedServerError(_)):
            break

         default:
            XCTFail()
         }
      }
   }

   func testActivationResponseWithInvalidLicense() {
      runTrialActivation(with: LicenseManagerTests.makeActivationResponseWithInvalidLicense()) { result in
         switch result {
         case .failure(.licenseValidationFailure(_)):
            break

         default:
            XCTFail()
         }
      }
   }
}
