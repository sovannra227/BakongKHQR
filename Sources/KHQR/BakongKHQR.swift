import CryptoKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Generates, decodes and verifies KHQR, the centralized QR code for payments in Cambodia.
public enum BakongKHQR {
    // MARK: - Generate

    /// Generates the KHQR of an individual account.
    public static func generateIndividual(_ info: IndividualInfo) throws -> KHQRData {
        try generate(Information(info), now: Date())
    }

    /// Generates the KHQR of a merchant account.
    public static func generateMerchant(_ info: MerchantInfo) throws -> KHQRData {
        try generate(Information(info), now: Date())
    }

    static func generate(_ information: Information, now: Date) throws -> KHQRData {
        let qr = try Generator.generate(information, now: now)
        return KHQRData(qr: qr, md5: md5(qr))
    }

    // MARK: - Decode

    /// Reads the fields of a KHQR string. The string is not validated; use `verify(_:)` for that.
    public static func decode(_ qr: String) -> KHQRDecodedData {
        Decoder.decode(qr)
    }

    /// Reads the tags of any EMV QR string, keyed by tag.
    public static func decodeNonKHQR(_ qr: String) -> [String: KHQRNode] {
        NonKHQRDecoder.decode(qr)
    }

    // MARK: - Verify

    /// Whether the string is a valid KHQR: its checksum matches, every field is well formed
    /// and, for a dynamic KHQR, it has not expired.
    public static func verify(_ qr: String) -> Bool {
        verify(qr, now: Date())
    }

    static func verify(_ qr: String, now: Date) -> Bool {
        (try? validate(qr, now: now)) != nil
    }

    static func validate(_ qr: String, now: Date) throws {
        guard hasChecksum(qr),
              CRC16.checksum(qr.jsSlice(0, -4)) == qr.jsSlice(-4).uppercased(),
              qr.jsLength >= EMV.MaxLength.khqr
        else {
            throw KHQRError.khqrInvalid
        }
        try Decoder.validate(qr, now: now)
    }

    /// Whether the string ends with the CRC tag: "6304" and four hexadecimal digits.
    private static func hasChecksum(_ qr: String) -> Bool {
        let tail = Array(qr.utf16.suffix(8))
        guard tail.count == 8, tail.prefix(4).elementsEqual("6304".utf16) else { return false }
        return tail.suffix(4).allSatisfy { unit in
            Unicode.Scalar(unit).map { Character($0).isHexDigit && $0.isASCII } ?? false
        }
    }

    // MARK: - Bakong Open API

    /// Generates a deep link to pay a KHQR.
    /// - Parameters:
    ///   - url: The `/v1/generate_deeplink_by_qr` endpoint of the Bakong Open API.
    ///   - qr: A valid KHQR string.
    ///   - sourceInfo: Identifies the calling app.
    public static func generateDeepLink(
        url: String,
        qr: String,
        sourceInfo: SourceInfo? = nil,
        session: URLSession = .shared
    ) async throws -> KHQRDeepLinkData {
        guard OpenAPI.isValidDeepLinkURL(url) else { throw KHQRError.invalidDeepLinkURL }
        guard verify(qr) else { throw KHQRError.khqrInvalid }

        var body: [String: Any] = ["qr": qr]
        if let sourceInfo {
            guard let appIconUrl = sourceInfo.appIconUrl, !appIconUrl.isEmpty,
                  let appName = sourceInfo.appName, !appName.isEmpty,
                  let appDeepLinkCallback = sourceInfo.appDeepLinkCallback, !appDeepLinkCallback.isEmpty
            else {
                throw KHQRError.invalidDeepLinkSourceInfo
            }
            body["sourceInfo"] = [
                "appIconUrl": appIconUrl,
                "appName": appName,
                "appDeepLinkCallback": appDeepLinkCallback,
            ]
        }

        let response = try await OpenAPI.post(url, body: body, session: session)
        switch OpenAPI.integer(response["errorCode"]) {
        case 5: throw KHQRError.invalidDeepLinkSourceInfo
        case 4: throw KHQRError.internalServerError
        default: break
        }
        guard let data = response["data"] as? [String: Any], let shortLink = data["shortLink"] as? String else {
            throw KHQRError.internalServerError
        }
        return KHQRDeepLinkData(shortLink: shortLink)
    }

    /// Whether a Bakong account exists.
    /// - Parameters:
    ///   - url: The `/v1/check_bakong_account` endpoint of the Bakong Open API.
    ///   - bakongID: The account ID, such as "john_smith@devb".
    public static func checkBakongAccount(
        url: String,
        bakongID: String,
        session: URLSession = .shared
    ) async throws -> Bool {
        guard bakongID.jsLength <= EMV.MaxLength.bakongAccount else { throw KHQRError.bakongAccountIDLengthInvalid }
        guard bakongID.components(separatedBy: "@").count == 2 else { throw KHQRError.bakongAccountIDInvalid }

        let response = try await OpenAPI.post(url, body: ["accountId": bakongID], session: session)
        switch OpenAPI.integer(response["errorCode"]) {
        case 11: return false
        case 12: throw KHQRError.bakongAccountIDInvalid
        default: return OpenAPI.integer(response["responseCode"]) == 0
        }
    }

    // MARK: -

    private static func md5(_ string: String) -> String {
        Insecure.MD5.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
