import Foundation

/// The details of a KHQR, whichever its merchant type.
struct Information {
    var isMerchant: Bool
    var bakongAccountID: String
    var merchantName: String
    var merchantCity: String
    var merchantID: String?
    var acquiringBank: String?
    var accountInformation: String?
    var currency: KHQRCurrency
    var amount: Double?
    var additionalData: AdditionalDataFields
    var language: LanguageFields
    var upiMerchantAccount: String?
    var expirationTimestamp: Int64?
    var merchantCategoryCode: String?
}

private extension Optional where Wrapped == String {
    /// Optional details given as an empty string count as not given.
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}

extension Information {
    init(_ info: IndividualInfo) {
        self.init(
            isMerchant: false,
            bakongAccountID: info.bakongAccountID,
            merchantName: info.merchantName,
            merchantCity: info.merchantCity,
            merchantID: nil,
            acquiringBank: info.acquiringBank.nonEmpty,
            accountInformation: info.accountInformation.nonEmpty,
            currency: info.currency,
            amount: info.amount,
            additionalData: AdditionalDataFields(
                billNumber: info.billNumber.nonEmpty,
                mobileNumber: info.mobileNumber.nonEmpty,
                storeLabel: info.storeLabel.nonEmpty,
                terminalLabel: info.terminalLabel.nonEmpty,
                purposeOfTransaction: info.purposeOfTransaction.nonEmpty
            ),
            language: LanguageFields(
                languagePreference: info.languagePreference.nonEmpty,
                merchantNameAlternateLanguage: info.merchantNameAlternateLanguage.nonEmpty,
                merchantCityAlternateLanguage: info.merchantCityAlternateLanguage.nonEmpty
            ),
            upiMerchantAccount: info.upiMerchantAccount.nonEmpty,
            expirationTimestamp: info.expirationTimestamp,
            merchantCategoryCode: info.merchantCategoryCode.nonEmpty
        )
    }

    init(_ info: MerchantInfo) {
        self.init(
            isMerchant: true,
            bakongAccountID: info.bakongAccountID,
            merchantName: info.merchantName,
            merchantCity: info.merchantCity,
            merchantID: info.merchantID,
            acquiringBank: info.acquiringBank,
            accountInformation: nil,
            currency: info.currency,
            amount: info.amount,
            additionalData: AdditionalDataFields(
                billNumber: info.billNumber.nonEmpty,
                mobileNumber: info.mobileNumber.nonEmpty,
                storeLabel: info.storeLabel.nonEmpty,
                terminalLabel: info.terminalLabel.nonEmpty,
                purposeOfTransaction: info.purposeOfTransaction.nonEmpty
            ),
            language: LanguageFields(
                languagePreference: info.languagePreference.nonEmpty,
                merchantNameAlternateLanguage: info.merchantNameAlternateLanguage.nonEmpty,
                merchantCityAlternateLanguage: info.merchantCityAlternateLanguage.nonEmpty
            ),
            upiMerchantAccount: info.upiMerchantAccount.nonEmpty,
            expirationTimestamp: info.expirationTimestamp,
            merchantCategoryCode: info.merchantCategoryCode.nonEmpty
        )
    }
}

enum Generator {
    /// Builds the KHQR string, checksum included.
    static func generate(_ information: Information, now: Date) throws -> String {
        let amount = information.amount ?? 0
        let isStatic = amount == 0
        let qrType = isStatic ? EMV.staticQR : EMV.dynamicQR

        var elements = [
            try Field.payloadFormatIndicator(EMV.payloadFormatIndicator, EMV.defaultPayloadFormatIndicator),
            try Field.pointOfInitiationMethod(EMV.pointOfInitiationMethod, qrType),
        ]

        let upi = try information.upiMerchantAccount.map {
            try Field.unionPayMerchantAccount(EMV.unionPayMerchantAccount, $0)
        }
        if let upi { elements.append(upi) }

        elements.append(try Field.globalUniqueIdentifier(
            information.isMerchant
                ? EMV.merchantAccountInformationMerchant
                : EMV.merchantAccountInformationIndividual,
            AccountFields(
                bakongAccountID: information.bakongAccountID,
                merchantID: information.merchantID,
                acquiringBank: information.acquiringBank,
                accountInformation: information.accountInformation,
                isMerchant: information.isMerchant
            )
        ))

        elements.append(try Field.merchantCategoryCode(
            EMV.merchantCategoryCode,
            information.merchantCategoryCode ?? EMV.defaultMerchantCategoryCode
        ))

        elements.append(try transactionCurrency(information.currency))
        if information.currency == .usd && upi != nil {
            throw KHQRError.upiAccountInformationInvalidCurrency
        }

        if !isStatic {
            elements.append(try Field.transactionAmount(
                EMV.transactionAmount,
                try amountString(amount, currency: information.currency)
            ))
        }

        elements.append(try Field.countryCode(EMV.countryCode, EMV.defaultCountryCode))
        elements.append(try Field.merchantName(EMV.merchantName, information.merchantName))
        elements.append(try Field.merchantCity(
            EMV.merchantCity,
            information.merchantCity.isEmpty ? EMV.defaultMerchantCity : information.merchantCity
        ))

        if !information.additionalData.isEmpty {
            elements.append(try Field.additionalData(EMV.additionalData, information.additionalData))
        }

        if !information.language.isEmpty {
            elements.append(try Field.merchantInformationLanguageTemplate(
                EMV.merchantInformationLanguageTemplate,
                information.language
            ))
        }

        if !isStatic {
            guard let expiration = information.expirationTimestamp, expiration != 0 else {
                throw KHQRError.expirationTimestampRequired
            }
            let nowMilliseconds = now.jsMilliseconds
            elements.append(try Field.timestamp(
                EMV.timestamp,
                creation: nowMilliseconds,
                expiration: Double(expiration),
                pointOfInitiation: qrType,
                now: nowMilliseconds
            ))
        }

        let payload = elements.map(\.encoded).joined() + EMV.crc + EMV.crcLength
        return payload + CRC16.checksum(payload)
    }

    private static func transactionCurrency(_ currency: KHQRCurrency) throws -> TLV {
        guard currency.rawValue != 0 else { throw KHQRError.currencyTypeRequired }
        guard KHQRCurrency.supported.contains(currency) else { throw KHQRError.unsupportedCurrency }
        return TLV(tag: EMV.transactionCurrency, value: String(currency.rawValue))
    }

    private static func amountString(_ amount: Double, currency: KHQRCurrency) throws -> String {
        guard amount.isFinite else { throw KHQRError.transactionAmountInvalid }

        let string: String
        if currency == .khr {
            guard amount.truncatingRemainder(dividingBy: 1) == 0 else { throw KHQRError.transactionAmountInvalid }
            string = JS.string(amount)
        } else {
            let parts = JS.string(amount).split(separator: ".", maxSplits: 1)
            if parts.count > 1 {
                let precision = parts[1]
                guard precision.count <= 2 else { throw KHQRError.transactionAmountInvalid }
                string = parts[0] + "." + precision + String(repeating: "0", count: 2 - precision.count)
            } else {
                string = String(parts[0])
            }
        }

        // Amounts too large to be written without an exponent.
        guard !string.contains("e") else { throw KHQRError.transactionAmountInvalid }
        return string
    }
}
