/// Sub tags of the merchant account information (tag 29 / 30).
struct AccountFields {
    var bakongAccountID: String?
    var merchantID: String?
    var acquiringBank: String?
    var accountInformation: String?
    var isMerchant = false
}

/// Sub tags of the additional data field template (tag 62).
struct AdditionalDataFields {
    var billNumber: String?
    var mobileNumber: String?
    var storeLabel: String?
    var terminalLabel: String?
    var purposeOfTransaction: String?

    var isEmpty: Bool {
        [billNumber, mobileNumber, storeLabel, terminalLabel, purposeOfTransaction]
            .allSatisfy { $0 == nil || $0 == "" }
    }
}

/// Sub tags of the merchant information language template (tag 64).
struct LanguageFields {
    var languagePreference: String?
    var merchantNameAlternateLanguage: String?
    var merchantCityAlternateLanguage: String?

    var isEmpty: Bool {
        [languagePreference, merchantNameAlternateLanguage, merchantCityAlternateLanguage]
            .allSatisfy { $0 == nil || $0 == "" }
    }
}

/// Builds each KHQR element, throwing the matching `KHQRError` when its value is not acceptable.
enum Field {
    private static func required(_ value: String?, maxLength: Int, missing: KHQRError, tooLong: KHQRError) throws -> String {
        guard let value, !value.isEmpty else { throw missing }
        guard value.jsLength <= maxLength else { throw tooLong }
        return value
    }

    /// A value that may be absent altogether but, when given, must be non-empty and short enough.
    private static func bounded(_ tag: String, _ value: String, maxLength: Int, error: KHQRError) throws -> TLV {
        guard !value.isEmpty, value.jsLength <= maxLength else { throw error }
        return TLV(tag: tag, value: value)
    }

    static func payloadFormatIndicator(_ tag: String, _ value: String?) throws -> TLV {
        TLV(tag: tag, value: try required(
            value,
            maxLength: EMV.MaxLength.payloadFormatIndicator,
            missing: .payloadFormatIndicatorTagRequired,
            tooLong: .payloadFormatIndicatorLengthInvalid
        ))
    }

    static func pointOfInitiationMethod(_ tag: String, _ value: String) throws -> TLV {
        guard value.jsLength <= EMV.MaxLength.pointOfInitiationMethod else { throw KHQRError.pointOfInitiationLengthInvalid }
        guard value == EMV.staticQR || value == EMV.dynamicQR else { throw KHQRError.pointOfInitiationMethodInvalid }
        return TLV(tag: tag, value: value)
    }

    static func unionPayMerchantAccount(_ tag: String, _ value: String) throws -> TLV {
        guard value.jsLength <= EMV.MaxLength.upiMerchant else { throw KHQRError.upiAccountInformationLengthInvalid }
        return TLV(tag: tag, value: value)
    }

    static func merchantCategoryCode(_ tag: String, _ value: String?) throws -> TLV {
        let value = try required(
            value,
            maxLength: EMV.MaxLength.merchantCategoryCode,
            missing: .merchantCategoryTagRequired,
            tooLong: .merchantCodeLengthInvalid
        )
        guard value.isJSNumeric else { throw KHQRError.invalidMerchantCategoryCode }
        return TLV(tag: tag, value: value)
    }

    static func transactionCurrency(_ tag: String, _ value: String?) throws -> TLV {
        let value = try required(
            value,
            maxLength: EMV.MaxLength.transactionCurrency,
            missing: .currencyTypeRequired,
            tooLong: .transactionCurrencyLengthInvalid
        )
        guard let code = JS.parseInt(value), KHQRCurrency.supported.contains(where: { $0.rawValue == code }) else {
            throw KHQRError.unsupportedCurrency
        }
        return TLV(tag: tag, value: value)
    }

    static func transactionAmount(_ tag: String, _ value: String?) throws -> TLV {
        guard let value, !value.isEmpty, value.jsLength <= EMV.MaxLength.amount, !value.contains("-") else {
            throw KHQRError.transactionAmountInvalid
        }
        return TLV(tag: tag, value: value)
    }

    static func countryCode(_ tag: String, _ value: String?) throws -> TLV {
        TLV(tag: tag, value: try required(
            value,
            maxLength: EMV.MaxLength.countryCode,
            missing: .countryCodeTagRequired,
            tooLong: .countryCodeLengthInvalid
        ))
    }

    static func merchantName(_ tag: String, _ value: String?) throws -> TLV {
        TLV(tag: tag, value: try required(
            value,
            maxLength: EMV.MaxLength.merchantName,
            missing: .merchantNameRequired,
            tooLong: .merchantNameLengthInvalid
        ))
    }

    static func merchantCity(_ tag: String, _ value: String?) throws -> TLV {
        TLV(tag: tag, value: try required(
            value,
            maxLength: EMV.MaxLength.merchantCity,
            missing: .merchantCityTagRequired,
            tooLong: .merchantCityLengthInvalid
        ))
    }

    static func crc(_ tag: String, _ value: String?) throws -> TLV {
        TLV(tag: tag, value: try required(
            value,
            maxLength: EMV.MaxLength.crc,
            missing: .crcTagRequired,
            tooLong: .crcLengthInvalid
        ))
    }

    static func globalUniqueIdentifier(_ tag: String, _ fields: AccountFields?) throws -> TLV {
        guard let fields else { throw KHQRError.merchantTypeRequired }

        var value = try bakongAccountID(fields.bakongAccountID).encoded

        if fields.isMerchant {
            let merchantID = TLV(tag: EMV.merchantAccountInformationMerchantID, value: try required(
                fields.merchantID,
                maxLength: EMV.MaxLength.merchantID,
                missing: .merchantIDRequired,
                tooLong: .merchantIDLengthInvalid
            ))
            let acquiringBank = try self.acquiringBank(fields.acquiringBank)
            value += merchantID.encoded + acquiringBank.encoded
        } else {
            if let accountInformation = fields.accountInformation {
                guard accountInformation.jsLength <= EMV.MaxLength.accountInformation else {
                    throw KHQRError.accountInformationLengthInvalid
                }
                value += TLV(tag: EMV.individualAccountInformation, value: accountInformation).encoded
            }
            if let acquiringBank = fields.acquiringBank {
                value += try self.acquiringBank(acquiringBank).encoded
            }
        }
        return TLV(tag: tag, value: value)
    }

    private static func bakongAccountID(_ value: String?) throws -> TLV {
        guard let value, !value.isEmpty else { throw KHQRError.bakongAccountIDRequired }
        guard value.jsLength <= EMV.MaxLength.bakongAccount else { throw KHQRError.bakongAccountIDLengthInvalid }
        guard value.contains("@") else { throw KHQRError.bakongAccountIDInvalid }
        return TLV(tag: EMV.bakongAccountIdentifier, value: value)
    }

    private static func acquiringBank(_ value: String?) throws -> TLV {
        TLV(tag: EMV.merchantAccountInformationAcquiringBank, value: try required(
            value,
            maxLength: EMV.MaxLength.acquiringBank,
            missing: .acquiringBankRequired,
            tooLong: .acquiringBankLengthInvalid
        ))
    }

    static func additionalData(_ tag: String, _ fields: AdditionalDataFields) throws -> TLV {
        var value = ""
        if let billNumber = fields.billNumber {
            value += try bounded(EMV.billNumber, billNumber, maxLength: EMV.MaxLength.billNumber, error: .billNumberLengthInvalid).encoded
        }
        if let mobileNumber = fields.mobileNumber {
            value += try bounded(EMV.mobileNumber, mobileNumber, maxLength: EMV.MaxLength.mobileNumber, error: .mobileNumberLengthInvalid).encoded
        }
        if let storeLabel = fields.storeLabel {
            value += try bounded(EMV.storeLabel, storeLabel, maxLength: EMV.MaxLength.storeLabel, error: .storeLabelLengthInvalid).encoded
        }
        if let terminalLabel = fields.terminalLabel {
            value += try bounded(EMV.terminalLabel, terminalLabel, maxLength: EMV.MaxLength.terminalLabel, error: .terminalLabelLengthInvalid).encoded
        }
        if let purpose = fields.purposeOfTransaction {
            value += try bounded(EMV.purposeOfTransaction, purpose, maxLength: EMV.MaxLength.purposeOfTransaction, error: .purposeOfTransactionLengthInvalid).encoded
        }
        return TLV(tag: tag, value: value)
    }

    static func merchantInformationLanguageTemplate(_ tag: String, _ fields: LanguageFields) throws -> TLV {
        let hasPreference = !(fields.languagePreference ?? "").isEmpty
        let hasName = !(fields.merchantNameAlternateLanguage ?? "").isEmpty
        if hasPreference && !hasName { throw KHQRError.merchantNameAlternateLanguageRequired }

        var value = ""
        if let name = fields.merchantNameAlternateLanguage {
            guard let preference = fields.languagePreference else { throw KHQRError.languagePreferenceRequired }
            value += try bounded(
                EMV.languagePreference, preference,
                maxLength: EMV.MaxLength.languagePreference,
                error: .languagePreferenceLengthInvalid
            ).encoded
            value += try bounded(
                EMV.merchantNameAlternateLanguage, name,
                maxLength: EMV.MaxLength.merchantNameAlternateLanguage,
                error: .merchantNameAlternateLanguageLengthInvalid
            ).encoded
        }
        if let city = fields.merchantCityAlternateLanguage {
            value += try bounded(
                EMV.merchantCityAlternateLanguage, city,
                maxLength: EMV.MaxLength.merchantCityAlternateLanguage,
                error: .merchantCityAlternateLanguageLengthInvalid
            ).encoded
        }
        return TLV(tag: tag, value: value)
    }

    /// - Parameters:
    ///   - creation: Creation time in milliseconds since 1970.
    ///   - expiration: Expiration time in milliseconds since 1970.
    ///   - pointOfInitiation: The value of tag 01; expiry rules only apply to dynamic KHQR.
    ///   - now: The current time in milliseconds since 1970.
    static func timestamp(_ tag: String, creation: Double, expiration: Double, pointOfInitiation: String?, now: Double) throws -> TLV {
        if pointOfInitiation == EMV.dynamicQR {
            if expiration.isNaN || expiration == 0 { throw KHQRError.expirationTimestampRequired }
            guard JS.string(expiration).jsLength == EMV.MaxLength.timestamp else {
                throw KHQRError.expirationTimestampLengthInvalid
            }
            // The range of a JavaScript `Date`.
            guard abs(expiration) <= 8.64e15 else { throw KHQRError.invalidDynamicKHQR }
            if expiration < creation { throw KHQRError.expirationTimestampInThePast }
            if expiration < now { throw KHQRError.khqrExpired }
        }

        let value = TLV(tag: EMV.creationTimestamp, value: JS.string(creation)).encoded
            + TLV(tag: EMV.expirationTimestamp, value: JS.string(expiration)).encoded
        return TLV(tag: tag, value: value)
    }
}
