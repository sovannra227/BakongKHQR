import Foundation

enum Decoder {
    /// Reads the fields of a KHQR string without checking that they are valid.
    static func decode(_ qr: String) -> KHQRDecodedData {
        var values: [String: String] = [:]
        var decoded = KHQRDecodedData()
        var isMerchant = false

        for element in Schema.elements(of: qr, mergingMerchantTag: true, stopOnRepeatedTag: true) {
            if element.originalTag == EMV.merchantAccountInformationMerchant {
                decoded.merchantType = EMV.merchantAccountInformationMerchant
                isMerchant = true
            } else if element.tag == EMV.merchantAccountInformationIndividual {
                decoded.merchantType = EMV.merchantAccountInformationIndividual
            }
            if Schema.contains(element.tag) {
                values[element.tag] = element.value
            }
        }

        for entry in Schema.tags {
            let value = values[entry.tag]
            if let field = entry.field {
                decoded[keyPath: field] = value
                continue
            }
            guard let value, let subTags = Schema.subTags[entry.tag] else { continue }
            for element in Schema.elements(of: value) {
                guard var field = subTags[element.tag] else { continue }
                // Sub tag 01 of a merchant KHQR is the merchant ID.
                if isMerchant && field == \.accountInformation { field = \.merchantID }
                decoded[keyPath: field] = element.value
            }
        }
        return decoded
    }

    /// Checks every field of a KHQR string, throwing the error of the first one that is not valid.
    static func validate(_ qr: String, now: Date) throws {
        let elements = Schema.elements(of: qr, mergingMerchantTag: true, stopOnRepeatedTag: true)
            .filter { Schema.contains($0.tag) }

        func has(_ tag: String) -> Bool {
            elements.contains { $0.tag == tag }
        }

        let isDynamic = elements.contains { $0.tag == EMV.pointOfInitiationMethod && $0.value == EMV.dynamicQR }
        if isDynamic && !has(EMV.transactionAmount) { throw KHQRError.invalidDynamicKHQR }
        if (isDynamic || has(EMV.transactionAmount)) && !has(EMV.timestamp) {
            throw KHQRError.expirationTimestampRequired
        }

        if let missing = Schema.tags.first(where: { $0.isRequired && !has($0.tag) }) {
            try validate(tag: missing.tag, value: nil, pointOfInitiation: nil, now: now)
        }

        var pointOfInitiation: String?
        for element in elements {
            if element.tag == EMV.pointOfInitiationMethod { pointOfInitiation = element.value }
            try validate(tag: element.tag, value: element.value, pointOfInitiation: pointOfInitiation, now: now)
        }
    }

    private static func validate(tag: String, value: String?, pointOfInitiation: String?, now: Date) throws {
        switch tag {
        case EMV.payloadFormatIndicator:
            _ = try Field.payloadFormatIndicator(tag, value)
        case EMV.pointOfInitiationMethod:
            _ = try Field.pointOfInitiationMethod(tag, value ?? "")
        case EMV.unionPayMerchantAccount:
            _ = try Field.unionPayMerchantAccount(tag, value ?? "")
        case EMV.merchantCategoryCode:
            _ = try Field.merchantCategoryCode(tag, value)
        case EMV.transactionCurrency:
            _ = try Field.transactionCurrency(tag, value)
        case EMV.transactionAmount:
            _ = try Field.transactionAmount(tag, value)
        case EMV.countryCode:
            _ = try Field.countryCode(tag, value)
        case EMV.merchantName:
            _ = try Field.merchantName(tag, value)
        case EMV.merchantCity:
            _ = try Field.merchantCity(tag, value)
        case EMV.crc:
            _ = try Field.crc(tag, value)

        case EMV.merchantAccountInformationIndividual:
            guard let value else {
                _ = try Field.globalUniqueIdentifier(tag, nil)
                return
            }
            let fields = subFields(of: value, in: tag)
            _ = try Field.globalUniqueIdentifier(tag, AccountFields(
                bakongAccountID: fields?.bakongAccountID,
                acquiringBank: fields?.acquiringBank,
                accountInformation: fields?.accountInformation
            ))
        case EMV.additionalData:
            let fields = subFields(of: value ?? "", in: tag)
            _ = try Field.additionalData(tag, AdditionalDataFields(
                billNumber: fields?.billNumber,
                mobileNumber: fields?.mobileNumber,
                storeLabel: fields?.storeLabel,
                terminalLabel: fields?.terminalLabel,
                purposeOfTransaction: fields?.purposeOfTransaction
            ))
        case EMV.merchantInformationLanguageTemplate:
            let fields = subFields(of: value ?? "", in: tag)
            _ = try Field.merchantInformationLanguageTemplate(tag, LanguageFields(
                languagePreference: fields?.languagePreference,
                merchantNameAlternateLanguage: fields?.merchantNameAlternateLanguage,
                merchantCityAlternateLanguage: fields?.merchantCityAlternateLanguage
            ))
        case EMV.timestamp:
            let fields = subFields(of: value ?? "", in: tag)
            _ = try Field.timestamp(
                tag,
                creation: fields.map { $0.creationTimestamp.map(JS.number) ?? 0 } ?? .nan,
                expiration: fields.map { $0.expirationTimestamp.map(JS.number) ?? 0 } ?? .nan,
                pointOfInitiation: pointOfInitiation,
                now: now.jsMilliseconds
            )
        default:
            break
        }
    }

    /// The known sub tags of a template value, or `nil` when it holds none.
    private static func subFields(of value: String, in tag: String) -> KHQRDecodedData? {
        guard let subTags = Schema.subTags[tag] else { return nil }
        var fields: KHQRDecodedData?
        for element in Schema.elements(of: value) {
            guard let field = subTags[element.tag] else { continue }
            var updated = fields ?? KHQRDecodedData()
            updated[keyPath: field] = element.value
            fields = updated
        }
        return fields
    }
}
