//
//  LicenseManager.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-12.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Dispatch
import Foundation
import Security

/**
 Used to activate, store, and load software licenses.
 */
public class LicenseManager {
   // MARK: - Private Properties

   private let knownPublicKeys: [Data]

   private let urlSession: URLSession
   private let jsonEncoder: JSONEncoder
   private let jsonDecoder: JSONDecoder

   // MARK: - Initialization

   /**
    Initialize a `LicenseManager` with an array of public keys that are known to the application.

    - Note: Normally, an application only has a single public key that is paired with the private
    key that the activation server has access to. However, in the event that the private key is lost,
    an application will have to maintain multiple public keys, one paired with the previous private
    key and one paired with the new private key, in order to validate past and future licenses.

    - Attention: There is no mechanism to revoke a public key. Therefore, use security best practices
    to guard the private key. An [HSM](https://en.wikipedia.org/wiki/Hardware_security_module) is
    recommended for generating the key pair and for computing digital signatures using the private key.

    - Parameter knownPublicKeys: An array of public keys. The keys must be exportable.
    */
   public init(knownPublicKeys: [SecKey]) {
      // `SecKey` is composed of the key data as well as various attributes (e.g. what the
      // key can be used for). The values of these attributes depend on how the key was
      // created. Since we do not care about most of the attributes (only that the key is
      // able to be used for signature verification), compare only the key data.
      self.knownPublicKeys = knownPublicKeys.map { key in
         return SecKeyCopyExternalRepresentation(key, nil)! as Data
      }

      let urlSessionConfiguration = URLSessionConfiguration.ephemeral
      urlSessionConfiguration.waitsForConnectivity = false
      urlSessionConfiguration.httpCookieAcceptPolicy = .never
      urlSessionConfiguration.httpShouldSetCookies = false
      urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

      self.urlSession = URLSession(configuration: urlSessionConfiguration)

      self.jsonEncoder = JSONEncoder()
      jsonEncoder.keyEncodingStrategy = .convertToSnakeCase

      self.jsonDecoder = JSONDecoder()
      jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
   }

   // MARK: - Loading the License

   public enum LicenseLoadError: Error {
      case licenseValidationFailure(LicenseValidationError)
   }

   /**
    Load and validate the stored license, if any.

    - Attention: This function only validates the integrity of the stored license. The caller is
    responsible for performing additional license validation (e.g. enforcing trial expiration).

    - Throws: `LicenseLoadError` if the license failed to be loaded or validated.

    - Returns: The license, if any.
    */
   public func loadLicense() throws -> License? {
      guard let signedBundleData = UserDefaults.standard.data(forKey: UserDefaultsKeys.license) else {
         return nil
      }

      do {
         return try extractLicense(fromSignedBundleData: signedBundleData)
      } catch let error as LicenseValidationError {
         throw LicenseLoadError.licenseValidationFailure(error)
      } catch {
         preconditionFailure("Unexpected error from `LicenseManager.extractLicense`: \(error).")
      }
   }

   // MARK: - Activation

   public enum ActivationError: Error {
      case missingSystemInformation

      case networkFailure(Error?)
      case serverRejectedRequest(httpStatusCode: Int)
      case missingServerResponse
      case invalidServerResponse(InvalidServerResponse)

      case licenseKeyNotFound
      case licenseQuotaExceeded
      case unrecognizedServerError(rawValue: String)

      case licenseValidationFailure(LicenseValidationError)
   }

   public enum InvalidServerResponse: Error {
      case deserializationFailure(Error)
      case mismatchedLicenseType
      case missingData
   }

   /**
    Send a request to the activation server to activate a trial for this computer.

    - Attention: The activation server may return an existing trial license if a trial was previously
    activated on this computer. This function only validates the integrity of the license. The caller
    is responsible for performing additional license validation (e.g. enforcing trial expiration).

    # Request Structure

    The request will use the HTTP `POST` method. The request JSON looks like
    ```
    {
      "computer_hardware_uuid": "9CAE2AA4-3268-4AF7-A75D-7B176251F0A7"
    }
    ```

    # Response Structure

    The activation server must respond with a 200 status code if it is sending a JSON payload; any
    other status code will be regarded as a rejection of the request.

    The response JSON looks like
    ```
    {
      "signed_license": "<base64-encoded data>"
    }
    ```

    The value of `signed_license` is a `LicenseInfo` struct wrapped in a `SignedBundle` struct,
    serialized using the Protocol Buffers library. See `SignedBundle.proto` and `LicenseInfo.proto`
    for the Protocol Buffers schemas.

    - Parameter endpointURL: The HTTP(S) URL of the trial activation endpoint. HTTPS is recommended
                             over plaintext HTTP.
    - Parameter completionQueue: The dispatch queue that the completion handler will run on.
    - Parameter completionHandler: The closure that is called when the activation succeeds or fails.
    - Parameter result: The license or an `ActivationError`. Note that the trial activation endpoint will
                        return a purchased license if a purchase was previously activated on this computer.
    */
   public func activateTrial(usingEndpoint endpointURL: URL,
                             runningCompletionHandlerOn completionQueue: DispatchQueue,
                             completionHandler: @escaping (_ result: Result<License, ActivationError>) -> Void) {
      guard let hardwareUUID = SystemInformation.shared.hardwareUUID else {
         completionQueue.async {
            completionHandler(.failure(.missingSystemInformation))
         }
         return
      }

      let trialActivationRequest = TrialActivationRequest(computerHardwareUUID: hardwareUUID)

      sendRequest(trialActivationRequest, toEndpoint: endpointURL) { (result: Result<TrialActivationResponse, ActivationError>) in
         let license: License
         let signedBundleData: Data
         do {
            (license, signedBundleData) = try self.extractTrialLicense(from: result)
         } catch let error as ActivationError {
            completionQueue.async {
               completionHandler(.failure(error))
            }
            return
         } catch {
            preconditionFailure("Unexpected error from `LicenseManager.extractTrialLicense`: \(error).")
         }

         self.storeLicense(signedBundleData: signedBundleData)

         completionQueue.async {
            completionHandler(.success(license))
         }
      }
   }

   private func extractTrialLicense(from result: Result<TrialActivationResponse, ActivationError>) throws -> (License, Data) {
      switch result {
      case .success(let responseBody):
         let signedBundleData = responseBody.signedLicense

         let license: License
         do {
            license = try self.extractLicense(fromSignedBundleData: signedBundleData)
         } catch let error as LicenseValidationError {
            throw ActivationError.licenseValidationFailure(error)
         } catch {
            preconditionFailure("Unexpected error from `LicenseManager.extractLicense`: \(error).")
         }

         return (license, signedBundleData)

      case .failure(let activationError):
         throw activationError
      }
   }

   /**
    Send a request to the activation server to activate a purchase for this computer.

    # Request Structure

    The request will use the HTTP `POST` method. The request JSON looks like
    ```
    {
      "computer_hardware_uuid": "9CAE2AA4-3268-4AF7-A75D-7B176251F0A7",
      "license_key": "<user’s license key>"
    }
    ```

    # Response Structure

    The activation server must respond with a 200 status code if it is sending a JSON payload; any
    other status code will be regarded as a rejection of the request.

    ## Successful Activation

    The response JSON for a successful activation looks like
    ```
    {
      "signed_license": "<base64-encoded data>"
    }
    ```

    The value of `signed_license` is a `LicenseInfo` struct wrapped in a `SignedBundle` struct,
    serialized using the Protocol Buffers library. See `SignedBundle.proto` and `LicenseInfo.proto`
    for the Protocol Buffers schemas.

    ## Failed Activation

    The response JSON for a failed activation looks like
    ```
    {
      "activation_error": "<error code>"
    }
    ```

    The value of `activation_error` can be one of the following:
    - `license_key_not_found`
    - `license_quota_exceeded`

    - Parameter licenseKey: The license key that corresponds to the user’s purchase.
    - Parameter endpointURL: The HTTP(S) URL of the purchase activation endpoint. HTTPS is
                             recommended over plaintext HTTP.
    - Parameter completionQueue: The dispatch queue that the completion handler will run on.
    - Parameter completionHandler: The closure that is called when the activation succeeds or fails.
    - Parameter result: The license or an `ActivationError`.
    */
   public func activatePurchase(forLicenseKey licenseKey: String,
                                usingEndpoint endpointURL: URL,
                                runningCompletionHandlerOn completionQueue: DispatchQueue,
                                completionHandler: @escaping (_ result: Result<PurchasedLicense, ActivationError>) -> Void) {
      guard let hardwareUUID = SystemInformation.shared.hardwareUUID else {
         completionQueue.async {
            completionHandler(.failure(.missingSystemInformation))
         }
         return
      }

      let purchaseActivationRequest = PurchaseActivationRequest(computerHardwareUUID: hardwareUUID,
                                                                licenseKey: licenseKey)

      sendRequest(purchaseActivationRequest, toEndpoint: endpointURL) { (result: Result<PurchaseActivationResponse, ActivationError>) in
         let purchasedLicense: PurchasedLicense
         let signedBundleData: Data
         do {
            (purchasedLicense, signedBundleData) = try self.extractPurchasedLicense(from: result)
         } catch let error as ActivationError {
            completionQueue.async {
               completionHandler(.failure(error))
            }
            return
         } catch {
            preconditionFailure("Unexpected error from `LicenseManager.extractPurchasedLicense`: \(error).")
         }

         self.storeLicense(signedBundleData: signedBundleData)

         completionQueue.async {
            completionHandler(.success(purchasedLicense))
         }
      }
   }

   private func extractPurchasedLicense(from result: Result<PurchaseActivationResponse, ActivationError>) throws -> (PurchasedLicense, Data) {
      switch result {
      case .success(let responseBody):
         if let activationError = responseBody.activationError {
            switch activationError {
            case .licenseKeyNotFound:
               throw ActivationError.licenseKeyNotFound

            case .licenseQuotaExceeded:
               throw ActivationError.licenseQuotaExceeded

            case .unrecognized(let rawValue):
               throw ActivationError.unrecognizedServerError(rawValue: rawValue)
            }
         }

         guard let signedBundleData = responseBody.signedLicense else {
            throw ActivationError.invalidServerResponse(.missingData)
         }

         let license: License
         do {
            license = try self.extractLicense(fromSignedBundleData: signedBundleData)
         } catch let error as LicenseValidationError {
            throw ActivationError.licenseValidationFailure(error)
         } catch {
            preconditionFailure("Unexpected error from `LicenseManager.extractLicense`: \(error).")
         }

         guard case .purchased(let purchasedLicense) = license else {
            throw ActivationError.invalidServerResponse(.mismatchedLicenseType)
         }
         return (purchasedLicense, signedBundleData)

      case .failure(let activationError):
         throw activationError
      }
   }

   private func sendRequest<Request: Encodable, Response: Decodable>(
      _ request: Request,
      toEndpoint endpointURL: URL,
      completionHandler: @escaping (Result<Response, ActivationError>) -> Void
   ) {
      let urlRequest = makeURLRequest(for: endpointURL,
                                      body: request)

      let dataTask = urlSession.dataTask(with: urlRequest) { (serializedResponseBody, urlResponse, error) in
         guard let urlResponse = urlResponse as? HTTPURLResponse else {
            completionHandler(.failure(.networkFailure(error)))
            return
         }

         let httpStatusCode = urlResponse.statusCode
         guard httpStatusCode == 200 else {
            completionHandler(.failure(.serverRejectedRequest(httpStatusCode: httpStatusCode)))
            return
         }

         guard let serializedResponseBody = serializedResponseBody else {
            completionHandler(.failure(.missingServerResponse))
            return
         }

         let response: Response
         do {
            response = try self.jsonDecoder.decode(Response.self,
                                                   from: serializedResponseBody)
         } catch {
            completionHandler(.failure(.invalidServerResponse(.deserializationFailure(error))))
            return
         }

         completionHandler(.success(response))
      }
      dataTask.resume()
   }

   private func makeURLRequest<Body: Encodable>(for url: URL, body: Body) -> URLRequest {
      var urlRequest = URLRequest(url: url)
      urlRequest.httpMethod = "POST"

      urlRequest.setValue("application/json",
                          forHTTPHeaderField: "Content-Type")
      urlRequest.setValue("application/json",
                          forHTTPHeaderField: "Accept")

      urlRequest.httpBody = try! jsonEncoder.encode(body)

      return urlRequest
   }

   private func storeLicense(signedBundleData: Data) {
      UserDefaults.standard.set(signedBundleData,
                                forKey: UserDefaultsKeys.license)
   }

   // MARK: - License Validation

   public enum LicenseValidationError: Error {
      case deserializationFailure(Error?)

      case unsupportedKeyType(internalKeyTypeID: Int)
      case invalidPublicKey(keyData: Data, error: Error?)
      case unknownPublicKey(SecKey)

      case unsupportedSignatureAlgorithm(internalSignatureAlgorithmID: Int)
      case invalidSignature(error: Error?)

      case missingSystemInformation
      case mismatchedComputer

      case missingData
   }

   private func extractLicense(fromSignedBundleData signedBundleData: Data) throws -> License {
      let signedBundle: SignedBundle
      do {
         signedBundle = try SignedBundle(serializedData: signedBundleData)
      } catch {
         throw LicenseValidationError.deserializationFailure(error)
      }

      try verifySignature(in: signedBundle)

      let licenseInfo: LicenseInfo
      do {
         licenseInfo = try LicenseInfo(serializedData: signedBundle.signedMessage)
      } catch {
         throw LicenseValidationError.deserializationFailure(error)
      }

      guard let hardwareUUIDData = SystemInformation.shared.hardwareUUID?.data else {
         throw LicenseValidationError.missingSystemInformation
      }
      guard licenseInfo.computerHardwareUuid == hardwareUUIDData else {
         throw LicenseValidationError.mismatchedComputer
      }

      guard let specificLicenseInfo = licenseInfo.specificInfo else {
         throw LicenseValidationError.missingData
      }
      do {
         switch specificLicenseInfo {
         case .trial(let trialLicenseInfo):
            let trialLicense = try TrialLicense(trialLicenseInfo: trialLicenseInfo,
                                                extraInfo: licenseInfo.extraInfo)
            return .trial(trialLicense)

         case .purchased(let purchasedLicenseInfo):
            let purchasedLicense = try PurchasedLicense(purchasedLicenseInfo: purchasedLicenseInfo,
                                                        extraInfo: licenseInfo.extraInfo)
            return .purchased(purchasedLicense)
         }
      } catch {
         throw LicenseValidationError.deserializationFailure(error)
      }
   }

   private func verifySignature(in signedBundle: SignedBundle) throws {
      let keyAttributes: [CFString: Any]
      switch signedBundle.keyType {
      case .rsa4096:
         keyAttributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 4096
         ]

      case .UNRECOGNIZED(let keyType):
         throw LicenseValidationError.unsupportedKeyType(internalKeyTypeID: keyType)
      }

      let publicKeyData = signedBundle.publicKey

      var unmanagedError: Unmanaged<CFError>?
      guard let publicKey = SecKeyCreateWithData(publicKeyData as CFData, keyAttributes as CFDictionary, &unmanagedError) else {
         let error = unmanagedError?.takeRetainedValue()
         throw LicenseValidationError.invalidPublicKey(keyData: signedBundle.publicKey,
                                                       error: error)
      }

      guard knownPublicKeys.contains(publicKeyData) else {
         throw LicenseValidationError.unknownPublicKey(publicKey)
      }

      let signatureAlgorithm: SecKeyAlgorithm
      switch signedBundle.signatureAlgorithm {
      case .rsaPssSha512:
         signatureAlgorithm = .rsaSignatureMessagePSSSHA512

      case .UNRECOGNIZED(let signatureAlgorithm):
         throw LicenseValidationError.unsupportedSignatureAlgorithm(internalSignatureAlgorithmID: signatureAlgorithm)
      }

      unmanagedError = nil
      guard SecKeyVerifySignature(publicKey, signatureAlgorithm, signedBundle.signedMessage as CFData, signedBundle.signature as CFData, &unmanagedError) else {
         let error = unmanagedError?.takeRetainedValue()
         throw LicenseValidationError.invalidSignature(error: error)
      }
   }
}
