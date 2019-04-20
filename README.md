# DMCoreLicensing

A macOS library that implements robust activation and validation of software licenses.

Requires Swift 4.2. Tested on macOS 10.14. MIT license.

## Design

### Goals

- To maximize the pain for users who decide to pirate the software.
- To minimize the pain for normal users.
- To be flexible enough to enable different licensing models.

### Specific Requirements

- Modifying the executable should be the only way for a user to bypass the license activation mechanism.
  - A user should not be able to bypass by modifying a file, intercepting network requests, or by using a license key generator. All of these bypasses are relatively painless for the user.
  - Modifying the executable introduces pain because (a) it breaks the code signature, which can be frightening to a user; and (b) a user will have to wait for a cracker to modify updated software, which delays (sometimes indefinitely) new features and bug fixes.
- The software should not require Internet access every time the application is launched.
  - The user may not always have Internet access, making it impossible to use the software in those circumstances.
  - Some software does not require any Internet access to function. Requiring Internet access every time the application is launched solely for the purpose of license validation will negatively impact the user’s impression of the software.
- The licenses should be customizable.

### Solution

#### Types of Licenses

##### Trial License

A free trial allows a potential customer to evaluate the software before making a purchase. A free trial expires after specific conditions are met.

The trial expiration can be designed in different ways: it could be based on time since activation, it could be based on usage time, it could be based on the number of application launches, and so on. Most of these techniques are easy to bypass since they would require storage of dynamic state. For example, a trial expiration based on the number of application launches would require the software to increment a persistent counter. However, the user can reset the counter, which would allow them to continue using the software.

This library implements trial expiration based on time since activation. This technique only relies on the system time. Although, technically, the system time is also stored dynamic state, changing the system time affects the whole system and will have obvious negative consequences for the user.

##### Purchased License

In order to enable different licensing models (e.g. full access vs. “Home Premium”/“Professional”/“Ultimate”), the library’s license data model has an `extraInfo` field that can be used to store any arbitrary information about the license.

#### License Activation

Activation involves sending the device’s hardware UUID and, if activating a purchase, the user’s license key to an activation server. The server returns the license if the software was previously activated on the device or if the device quota for the license has not been exceeded.

The software stores the license and validates it when needed (e.g. when the application is launched).

#### License Validation

This library relies on [public-key cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography), specifically [digital signatures](https://en.wikipedia.org/wiki/Digital_signature), to verify the integrity of the license.

A digital signature is an encrypted hash of a message. The workflow looks like the following:

1. The message is hashed using an algorithm such as [SHA-512](https://en.wikipedia.org/wiki/SHA-512). The output is called the “digest”.
2. The digest is encrypted using a private key. The output is called the “signature”.
3. The message is always transmitted along with its signature.
4. The signature can be decrypted using the corresponding public key to retrieve the original digest.
5. A new digest can be computed and compared to the original in order to verify the integrity of the message.

The activation server computes the signature of the license data before transmitting the license data and its signature to the client. This library (the client) stores the license data along with its signature.

Whenever the library loads the license, it verifies that the signature matches the license data and that the stored device hardware UUID matches the host device’s hardware UUID.

The application is responsible for performing additional license validation (e.g. enforcing trial expiration). This separation of concerns gives the application more flexibility in its software licensing design.

#### Key Technologies

- [Protocol Buffers](https://en.wikipedia.org/wiki/Protocol_Buffers) for the serialization of the license.
  - A schema-based serialization technology provides more guarantees around backwards-compatibility and stability.
- [JSON](https://en.wikipedia.org/wiki/JSON) over [HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol)(S) for sending requests to the activation server.
  - HTTP(S) and JSON are widely supported, so using these technologies keeps the number of dependencies under control.
  - Applications should use [HTTPS](https://en.wikipedia.org/wiki/HTTPS) instead of plaintext HTTP.
- [Digital signatures](https://en.wikipedia.org/wiki/Digital_signature), as explained in the License Validation section.

## Usage

See the `LicenseClient` documentation.
