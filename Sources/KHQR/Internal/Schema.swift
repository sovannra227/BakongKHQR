/// The tags a KHQR string is made of, in the order they are decoded.
enum Schema {
    struct Tag {
        let tag: String
        let field: WritableKeyPath<KHQRDecodedData, String?>?
        let isRequired: Bool
        let hasSubTags: Bool

        init(_ tag: String, _ field: WritableKeyPath<KHQRDecodedData, String?>? = nil, required: Bool = false, sub: Bool = false) {
            self.tag = tag
            self.field = field
            isRequired = required
            hasSubTags = sub
        }
    }

    static let tags: [Tag] = [
        Tag("00", \.payloadFormatIndicator, required: true),
        Tag("01", \.pointOfInitiationMethod),
        Tag("15", \.unionPayMerchant),
        Tag("29", required: true, sub: true),
        Tag("52", \.merchantCategoryCode, required: true),
        Tag("53", \.transactionCurrency, required: true),
        Tag("54", \.transactionAmount),
        Tag("58", \.countryCode, required: true),
        Tag("59", \.merchantName, required: true),
        Tag("60", \.merchantCity, required: true),
        Tag("62", sub: true),
        Tag("64", sub: true),
        Tag("99", sub: true),
        Tag("63", \.crc, required: true),
    ]

    static func contains(_ tag: String) -> Bool {
        tags.contains { $0.tag == tag }
    }

    /// The fields held by the sub tags of each template tag.
    static let subTags: [String: [String: WritableKeyPath<KHQRDecodedData, String?>]] = [
        "29": [
            EMV.bakongAccountIdentifier: \.bakongAccountID,
            EMV.merchantAccountInformationMerchantID: \.accountInformation,
            EMV.merchantAccountInformationAcquiringBank: \.acquiringBank,
        ],
        "62": [
            EMV.billNumber: \.billNumber,
            EMV.mobileNumber: \.mobileNumber,
            EMV.storeLabel: \.storeLabel,
            EMV.purposeOfTransaction: \.purposeOfTransaction,
            EMV.terminalLabel: \.terminalLabel,
        ],
        "64": [
            EMV.languagePreference: \.languagePreference,
            EMV.merchantNameAlternateLanguage: \.merchantNameAlternateLanguage,
            EMV.merchantCityAlternateLanguage: \.merchantCityAlternateLanguage,
        ],
        "99": [
            EMV.creationTimestamp: \.creationTimestamp,
            EMV.expirationTimestamp: \.expirationTimestamp,
        ],
    ]

    /// Splits a string into its elements. Stops at the first element that repeats the tag
    /// before it or that does not shorten what is left, so malformed input cannot loop.
    static func elements(of string: String, mergingMerchantTag: Bool = false, stopOnRepeatedTag: Bool = false) -> [(tag: String, originalTag: String, value: String)] {
        var elements: [(tag: String, originalTag: String, value: String)] = []
        var remaining = string
        var lastTag = ""

        while !remaining.isEmpty {
            let cut = TLVCut(remaining)
            var tag = cut.tag
            if stopOnRepeatedTag && tag == lastTag { break }
            if mergingMerchantTag && tag == EMV.merchantAccountInformationMerchant {
                tag = EMV.merchantAccountInformationIndividual
            }
            elements.append((tag, cut.tag, cut.value))

            guard cut.rest.jsLength < remaining.jsLength else { break }
            remaining = cut.rest
            lastTag = tag
        }
        return elements
    }
}
