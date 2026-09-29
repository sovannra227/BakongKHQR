/// EMV tag identifiers, default values and maximum field lengths used by KHQR.
enum EMV {
    static let payloadFormatIndicator = "00"
    static let defaultPayloadFormatIndicator = "01"
    static let pointOfInitiationMethod = "01"
    static let staticQR = "11"
    static let dynamicQR = "12"
    static let merchantAccountInformationIndividual = "29"
    static let merchantAccountInformationMerchant = "30"
    static let bakongAccountIdentifier = "00"
    static let merchantAccountInformationMerchantID = "01"
    static let individualAccountInformation = "01"
    static let merchantAccountInformationAcquiringBank = "02"
    static let merchantCategoryCode = "52"
    static let defaultMerchantCategoryCode = "5999"
    static let transactionCurrency = "53"
    static let transactionAmount = "54"
    static let countryCode = "58"
    static let defaultCountryCode = "KH"
    static let merchantName = "59"
    static let merchantCity = "60"
    static let defaultMerchantCity = "Phnom Penh"
    static let crc = "63"
    static let crcLength = "04"
    static let additionalData = "62"
    static let billNumber = "01"
    static let mobileNumber = "02"
    static let storeLabel = "03"
    static let terminalLabel = "07"
    static let purposeOfTransaction = "08"
    static let timestamp = "99"
    static let creationTimestamp = "00"
    static let expirationTimestamp = "01"
    static let merchantInformationLanguageTemplate = "64"
    static let languagePreference = "00"
    static let merchantNameAlternateLanguage = "01"
    static let merchantCityAlternateLanguage = "02"
    static let unionPayMerchantAccount = "15"

    enum MaxLength {
        static let khqr = 12
        static let merchantName = 25
        static let bakongAccount = 32
        static let amount = 13
        static let countryCode = 3
        static let merchantCategoryCode = 4
        static let merchantCity = 15
        static let timestamp = 13
        static let transactionCurrency = 3
        static let payloadFormatIndicator = 2
        static let pointOfInitiationMethod = 2
        static let crc = 4
        static let billNumber = 25
        static let storeLabel = 25
        static let terminalLabel = 25
        static let purposeOfTransaction = 25
        static let merchantID = 32
        static let acquiringBank = 32
        static let mobileNumber = 25
        static let accountInformation = 32
        static let upiMerchant = 99
        static let languagePreference = 2
        static let merchantNameAlternateLanguage = 25
        static let merchantCityAlternateLanguage = 15
    }
}
