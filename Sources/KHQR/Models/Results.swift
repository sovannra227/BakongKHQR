/// A generated KHQR string and the MD5 hash used to look its transaction up.
public struct KHQRData: Equatable, Codable, Sendable {
    public let qr: String
    public let md5: String
}

public struct KHQRDeepLinkData: Equatable, Codable, Sendable {
    public let shortLink: String
}

/// The fields of a decoded KHQR string. A field is `nil` when its tag is absent.
public struct KHQRDecodedData: Equatable, Codable, Sendable {
    /// "29" for an individual KHQR, "30" for a merchant KHQR.
    public var merchantType: String?
    public var bakongAccountID: String?
    public var accountInformation: String?
    public var merchantID: String?
    public var acquiringBank: String?
    public var billNumber: String?
    public var mobileNumber: String?
    public var storeLabel: String?
    public var terminalLabel: String?
    public var purposeOfTransaction: String?
    public var languagePreference: String?
    public var merchantNameAlternateLanguage: String?
    public var merchantCityAlternateLanguage: String?
    public var creationTimestamp: String?
    public var expirationTimestamp: String?
    public var payloadFormatIndicator: String?
    public var pointOfInitiationMethod: String?
    public var unionPayMerchant: String?
    public var merchantCategoryCode: String?
    public var transactionCurrency: String?
    public var transactionAmount: String?
    public var countryCode: String?
    public var merchantName: String?
    public var merchantCity: String?
    public var crc: String?

    public init() {}
}

/// A value of an EMV QR string decoded without KHQR rules: either a plain value or a
/// template holding further tags.
public enum KHQRNode: Equatable, Sendable {
    case value(String)
    case template([String: KHQRNode])

    public var value: String? {
        if case .value(let value) = self { return value }
        return nil
    }

    public var template: [String: KHQRNode]? {
        if case .template(let template) = self { return template }
        return nil
    }

    public subscript(tag: String) -> KHQRNode? { template?[tag] }
}

/// The response envelope of the JavaScript SDK, for callers that prefer a status object
/// over `throws`.
public struct KHQRResponse<Value> {
    public struct Status: Equatable, Sendable {
        /// `0` on success, `1` on failure.
        public let code: Int
        public let errorCode: Int?
        public let message: String?
    }

    public let status: Status
    public let data: Value?

    public init(catching body: () throws -> Value) {
        do {
            self.init(data: try body())
        } catch {
            self.init(error: error)
        }
    }

    public init(catching body: () async throws -> Value) async {
        do {
            self.init(data: try await body())
        } catch {
            self.init(error: error)
        }
    }

    private init(data: Value) {
        status = Status(code: 0, errorCode: nil, message: nil)
        self.data = data
    }

    private init(error: Error) {
        let error = error as? KHQRError ?? .internalServerError
        status = Status(code: 1, errorCode: error.code, message: error.message)
        data = nil
    }
}

extension KHQRResponse: Equatable where Value: Equatable {}
extension KHQRResponse: Sendable where Value: Sendable {}
