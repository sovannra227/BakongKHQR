import Foundation

/// An error raised by the KHQR SDK. `code` and `message` match the error table of the
/// Bakong KHQR JavaScript SDK.
public struct KHQRError: Error, Equatable, Hashable, Sendable {
    public let code: Int
    public let message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

extension KHQRError: LocalizedError {
    public var errorDescription: String? { message }
}

extension KHQRError {
    public static let bakongAccountIDRequired = KHQRError(code: 1, message: "Bakong Account ID cannot be null or empty")
    public static let merchantNameRequired = KHQRError(code: 2, message: "Merchant name cannot be null or empty")
    public static let bakongAccountIDInvalid = KHQRError(code: 3, message: "Bakong Account ID is invalid")
    public static let transactionAmountInvalid = KHQRError(code: 4, message: "Amount is invalid")
    public static let merchantTypeRequired = KHQRError(code: 5, message: "Merchant type cannot be null or empty")
    public static let bakongAccountIDLengthInvalid = KHQRError(code: 6, message: "Bakong Account ID Length is Invalid")
    public static let merchantNameLengthInvalid = KHQRError(code: 7, message: "Merchant Name Length is invalid")
    public static let khqrInvalid = KHQRError(code: 8, message: "KHQR provided is invalid")
    public static let currencyTypeRequired = KHQRError(code: 9, message: "Currency type cannot be null or empty")
    public static let billNumberLengthInvalid = KHQRError(code: 10, message: "Bill Name Length is invalid")
    public static let storeLabelLengthInvalid = KHQRError(code: 11, message: "Store Label Length is invalid")
    public static let terminalLabelLengthInvalid = KHQRError(code: 12, message: "Terminal Label Length is invalid")
    public static let connectionTimeout = KHQRError(code: 13, message: "Cannot reach Bakong Open API service. Please check internet connection")
    public static let invalidDeepLinkSourceInfo = KHQRError(code: 14, message: "Source Info for Deep Link is invalid")
    public static let internalServerError = KHQRError(code: 15, message: "Internal server error")
    public static let payloadFormatIndicatorLengthInvalid = KHQRError(code: 16, message: "Payload Format indicator Length is invalid")
    public static let pointOfInitiationLengthInvalid = KHQRError(code: 17, message: "Point of initiation Length is invalid")
    public static let merchantCodeLengthInvalid = KHQRError(code: 18, message: "Merchant code Length is invalid")
    public static let transactionCurrencyLengthInvalid = KHQRError(code: 19, message: "Transaction currency Length is invalid")
    public static let countryCodeLengthInvalid = KHQRError(code: 20, message: "Country code Length is invalid")
    public static let merchantCityLengthInvalid = KHQRError(code: 21, message: "Merchant city Length is invalid")
    public static let crcLengthInvalid = KHQRError(code: 22, message: "CRC Length is invalid")
    public static let payloadFormatIndicatorTagRequired = KHQRError(code: 23, message: "Payload format indicator tag required")
    public static let crcTagRequired = KHQRError(code: 24, message: "CRC tag required")
    public static let merchantCategoryTagRequired = KHQRError(code: 25, message: "Merchant category tag required")
    public static let countryCodeTagRequired = KHQRError(code: 26, message: "Country Code cannot be null or empty")
    public static let merchantCityTagRequired = KHQRError(code: 27, message: "Merchant City cannot be null or empty")
    public static let unsupportedCurrency = KHQRError(code: 28, message: "Unsupported currency")
    public static let invalidDeepLinkURL = KHQRError(code: 29, message: "Deep Link URL is not valid")
    public static let merchantIDRequired = KHQRError(code: 30, message: "Merchant ID cannot be null or empty")
    public static let acquiringBankRequired = KHQRError(code: 31, message: "Acquiring Bank cannot be null or empty")
    public static let merchantIDLengthInvalid = KHQRError(code: 32, message: "Merchant ID Length is invalid")
    public static let acquiringBankLengthInvalid = KHQRError(code: 33, message: "Acquiring Bank Length is invalid")
    public static let mobileNumberLengthInvalid = KHQRError(code: 34, message: "Mobile Number Length is invalid")
    public static let accountInformationLengthInvalid = KHQRError(code: 35, message: "Account Information Length is invalid")
    public static let tagNotInOrder = KHQRError(code: 36, message: "Tag is not in order")
    public static let languagePreferenceRequired = KHQRError(code: 37, message: "Language Preference cannot be null or empty")
    public static let languagePreferenceLengthInvalid = KHQRError(code: 38, message: "Language Preference Length is invalid")
    public static let merchantNameAlternateLanguageRequired = KHQRError(code: 39, message: "Merchant Name Alternate Language cannot be null or empty")
    public static let merchantNameAlternateLanguageLengthInvalid = KHQRError(code: 40, message: "Merchant Name Alternate Language Length is invalid")
    public static let merchantCityAlternateLanguageLengthInvalid = KHQRError(code: 41, message: "Merchant City Alternate Language Length is invalid")
    public static let purposeOfTransactionLengthInvalid = KHQRError(code: 42, message: "Purpose of Transaction Length is invalid")
    public static let upiAccountInformationLengthInvalid = KHQRError(code: 43, message: "Upi Account Information Length is invalid")
    public static let upiAccountInformationInvalidCurrency = KHQRError(code: 44, message: "Upi Account Information Length does not accept USD")
    public static let expirationTimestampRequired = KHQRError(code: 45, message: "Expiration timestamp is required for dynamic KHQR")
    public static let khqrExpired = KHQRError(code: 46, message: "This dynamic KHQR has expired")
    public static let invalidDynamicKHQR = KHQRError(code: 47, message: "This dynamic KHQR has invalid field transaction amount")
    public static let pointOfInitiationMethodInvalid = KHQRError(code: 48, message: "Point of Initiation Method is invalid")
    public static let expirationTimestampLengthInvalid = KHQRError(code: 49, message: "Expiration timestamp length is invalid")
    public static let expirationTimestampInThePast = KHQRError(code: 50, message: "Expiration timestamp is in the past")
    public static let invalidMerchantCategoryCode = KHQRError(code: 51, message: "Invalid merchant category code")
}
