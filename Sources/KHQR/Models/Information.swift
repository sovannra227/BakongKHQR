/// The details of an individual (tag 29) KHQR.
public struct IndividualInfo: Equatable, Sendable {
    public var bakongAccountID: String
    public var merchantName: String
    /// Falls back to "Phnom Penh" when empty.
    public var merchantCity: String
    public var accountInformation: String?
    public var acquiringBank: String?
    public var currency: KHQRCurrency
    /// Leave `nil` or `0` for a static KHQR. KHR amounts must be whole numbers and USD amounts
    /// may have at most two decimal places.
    public var amount: Double?
    public var billNumber: String?
    public var storeLabel: String?
    public var terminalLabel: String?
    public var mobileNumber: String?
    public var purposeOfTransaction: String?
    public var languagePreference: String?
    public var merchantNameAlternateLanguage: String?
    public var merchantCityAlternateLanguage: String?
    public var upiMerchantAccount: String?
    /// Milliseconds since 1970. Required when `amount` is set.
    public var expirationTimestamp: Int64?
    /// Defaults to "5999".
    public var merchantCategoryCode: String?

    public init(
        bakongAccountID: String,
        merchantName: String,
        merchantCity: String,
        accountInformation: String? = nil,
        acquiringBank: String? = nil,
        currency: KHQRCurrency = .khr,
        amount: Double? = nil,
        billNumber: String? = nil,
        storeLabel: String? = nil,
        terminalLabel: String? = nil,
        mobileNumber: String? = nil,
        purposeOfTransaction: String? = nil,
        languagePreference: String? = nil,
        merchantNameAlternateLanguage: String? = nil,
        merchantCityAlternateLanguage: String? = nil,
        upiMerchantAccount: String? = nil,
        expirationTimestamp: Int64? = nil,
        merchantCategoryCode: String? = nil
    ) {
        self.bakongAccountID = bakongAccountID
        self.merchantName = merchantName
        self.merchantCity = merchantCity
        self.accountInformation = accountInformation
        self.acquiringBank = acquiringBank
        self.currency = currency
        self.amount = amount
        self.billNumber = billNumber
        self.storeLabel = storeLabel
        self.terminalLabel = terminalLabel
        self.mobileNumber = mobileNumber
        self.purposeOfTransaction = purposeOfTransaction
        self.languagePreference = languagePreference
        self.merchantNameAlternateLanguage = merchantNameAlternateLanguage
        self.merchantCityAlternateLanguage = merchantCityAlternateLanguage
        self.upiMerchantAccount = upiMerchantAccount
        self.expirationTimestamp = expirationTimestamp
        self.merchantCategoryCode = merchantCategoryCode
    }
}

/// The details of a merchant (tag 30) KHQR.
public struct MerchantInfo: Equatable, Sendable {
    public var bakongAccountID: String
    public var merchantName: String
    /// Falls back to "Phnom Penh" when empty.
    public var merchantCity: String
    public var merchantID: String
    public var acquiringBank: String
    public var currency: KHQRCurrency
    /// Leave `nil` or `0` for a static KHQR. KHR amounts must be whole numbers and USD amounts
    /// may have at most two decimal places.
    public var amount: Double?
    public var billNumber: String?
    public var storeLabel: String?
    public var terminalLabel: String?
    public var mobileNumber: String?
    public var purposeOfTransaction: String?
    public var languagePreference: String?
    public var merchantNameAlternateLanguage: String?
    public var merchantCityAlternateLanguage: String?
    public var upiMerchantAccount: String?
    /// Milliseconds since 1970. Required when `amount` is set.
    public var expirationTimestamp: Int64?
    /// Defaults to "5999".
    public var merchantCategoryCode: String?

    public init(
        bakongAccountID: String,
        merchantName: String,
        merchantCity: String,
        merchantID: String,
        acquiringBank: String,
        currency: KHQRCurrency = .khr,
        amount: Double? = nil,
        billNumber: String? = nil,
        storeLabel: String? = nil,
        terminalLabel: String? = nil,
        mobileNumber: String? = nil,
        purposeOfTransaction: String? = nil,
        languagePreference: String? = nil,
        merchantNameAlternateLanguage: String? = nil,
        merchantCityAlternateLanguage: String? = nil,
        upiMerchantAccount: String? = nil,
        expirationTimestamp: Int64? = nil,
        merchantCategoryCode: String? = nil
    ) {
        self.bakongAccountID = bakongAccountID
        self.merchantName = merchantName
        self.merchantCity = merchantCity
        self.merchantID = merchantID
        self.acquiringBank = acquiringBank
        self.currency = currency
        self.amount = amount
        self.billNumber = billNumber
        self.storeLabel = storeLabel
        self.terminalLabel = terminalLabel
        self.mobileNumber = mobileNumber
        self.purposeOfTransaction = purposeOfTransaction
        self.languagePreference = languagePreference
        self.merchantNameAlternateLanguage = merchantNameAlternateLanguage
        self.merchantCityAlternateLanguage = merchantCityAlternateLanguage
        self.upiMerchantAccount = upiMerchantAccount
        self.expirationTimestamp = expirationTimestamp
        self.merchantCategoryCode = merchantCategoryCode
    }
}

/// Identifies the calling app when generating a deep link. When supplied, every field must
/// be non-empty.
public struct SourceInfo: Equatable, Sendable {
    public var appIconUrl: String?
    public var appName: String?
    public var appDeepLinkCallback: String?

    public init(appIconUrl: String?, appName: String?, appDeepLinkCallback: String?) {
        self.appIconUrl = appIconUrl
        self.appName = appName
        self.appDeepLinkCallback = appDeepLinkCallback
    }
}
