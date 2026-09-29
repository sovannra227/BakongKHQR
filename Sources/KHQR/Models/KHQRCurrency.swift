/// An ISO 4217 numeric currency code. KHQR supports `khr` and `usd`.
public struct KHQRCurrency: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let khr = KHQRCurrency(rawValue: 116)
    public static let usd = KHQRCurrency(rawValue: 840)

    static let supported: [KHQRCurrency] = [.khr, .usd]
}
