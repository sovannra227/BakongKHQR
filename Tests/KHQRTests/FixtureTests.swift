import XCTest
@testable import KHQR

/// Checks the package against what the Bakong KHQR JavaScript SDK returns for the same input.
/// The vectors are recorded by `Scripts/record-fixtures.js`.
final class FixtureTests: XCTestCase {
    private struct Vector {
        let kind: String
        let now: Date
        let input: Any
        let output: Any
        let reason: Any?
    }

    private static let vectors: [Vector] = {
        guard let url = Bundle.module.url(forResource: "vectors", withExtension: "json", subdirectory: "Fixtures"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        return json.compactMap { vector in
            guard let kind = vector["kind"] as? String,
                  let now = vector["now"] as? NSNumber,
                  let input = vector["input"],
                  let output = vector["output"]
            else { return nil }
            return Vector(
                kind: kind,
                now: Date(timeIntervalSince1970: now.doubleValue / 1000),
                input: input,
                output: output,
                reason: vector["reason"]
            )
        }
    }()

    private func vectors(_ kinds: String...) throws -> [Vector] {
        let vectors = Self.vectors.filter { kinds.contains($0.kind) }
        XCTAssertFalse(vectors.isEmpty, "No vectors recorded for \(kinds)")
        return vectors
    }

    func testGenerate() throws {
        for vector in try vectors("generateIndividual", "generateMerchant") {
            let input = try XCTUnwrap(vector.input as? [String: Any])
            let output = try XCTUnwrap(vector.output as? [String: Any])
            let information = try information(input, isMerchant: vector.kind == "generateMerchant")
            let result = Result { try BakongKHQR.generate(information, now: vector.now) }
            let context = "\(vector.kind) \(input) at \(vector.now.jsMilliseconds)"

            switch result {
            case .success(let data):
                XCTAssertEqual(data.qr, output["qr"] as? String, context)
                XCTAssertEqual(data.md5, output["md5"] as? String, context)
            case .failure(let error):
                if output["crash"] != nil { continue }
                XCTAssertEqual((error as? KHQRError)?.code, (output["errorCode"] as? NSNumber)?.intValue, context)
            }
        }
    }

    func testVerify() throws {
        for vector in try vectors("verify") {
            let qr = try XCTUnwrap(vector.input as? String)
            let context = "\(qr) at \(vector.now.jsMilliseconds)"

            XCTAssertEqual(BakongKHQR.verify(qr, now: vector.now), vector.output as? Bool, context)

            let result = Result { try BakongKHQR.validate(qr, now: vector.now) }
            switch (result, vector.reason) {
            case (.success, let reason):
                XCTAssertTrue(reason == nil || reason is NSNull, "Expected \(String(describing: reason)): \(context)")
            case (.failure, let reason as String):
                XCTAssertEqual(reason, "crash", context)
            case (.failure(let error), let reason):
                XCTAssertEqual((error as? KHQRError)?.code, (reason as? NSNumber)?.intValue, context)
            }
        }
    }

    func testDecode() throws {
        let fields: [(String, KeyPath<KHQRDecodedData, String?>)] = [
            ("merchantType", \.merchantType),
            ("bakongAccountID", \.bakongAccountID),
            ("accountInformation", \.accountInformation),
            ("merchantID", \.merchantID),
            ("acquiringBank", \.acquiringBank),
            ("billNumber", \.billNumber),
            ("mobileNumber", \.mobileNumber),
            ("storeLabel", \.storeLabel),
            ("terminalLabel", \.terminalLabel),
            ("purposeOfTransaction", \.purposeOfTransaction),
            ("languagePreference", \.languagePreference),
            ("merchantNameAlternateLanguage", \.merchantNameAlternateLanguage),
            ("merchantCityAlternateLanguage", \.merchantCityAlternateLanguage),
            ("creationTimestamp", \.creationTimestamp),
            ("expirationTimestamp", \.expirationTimestamp),
            ("payloadFormatIndicator", \.payloadFormatIndicator),
            ("pointofInitiationMethod", \.pointOfInitiationMethod),
            ("unionPayMerchant", \.unionPayMerchant),
            ("merchantCategoryCode", \.merchantCategoryCode),
            ("transactionCurrency", \.transactionCurrency),
            ("transactionAmount", \.transactionAmount),
            ("countryCode", \.countryCode),
            ("merchantName", \.merchantName),
            ("merchantCity", \.merchantCity),
            ("crc", \.crc),
        ]

        for vector in try vectors("decode") {
            let qr = try XCTUnwrap(vector.input as? String)
            let expected = try XCTUnwrap(vector.output as? [String: Any])
            let decoded = BakongKHQR.decode(qr)

            for (name, field) in fields {
                XCTAssertEqual(decoded[keyPath: field], expected[name] as? String, "\(name) of \(qr)")
            }
        }
    }

    func testDecodeNonKHQR() throws {
        for vector in try vectors("decodeNonKhqr") {
            let qr = try XCTUnwrap(vector.input as? String)
            let expected = try XCTUnwrap(vector.output as? [String: Any])
            let decoded = BakongKHQR.decodeNonKHQR(qr).mapValues(\.json)

            XCTAssertEqual(decoded as NSDictionary, expected as NSDictionary, qr)
        }
    }

    private func information(_ input: [String: Any], isMerchant: Bool) throws -> Information {
        func string(_ name: String) -> String? { input[name] as? String }

        let currency = KHQRCurrency(rawValue: try XCTUnwrap((input["currency"] as? NSNumber)?.intValue))
        let amount = (input["amount"] as? NSNumber)?.doubleValue
        let expirationTimestamp = (input["expirationTimestamp"] as? NSNumber)?.int64Value

        if isMerchant {
            return Information(MerchantInfo(
                bakongAccountID: try XCTUnwrap(string("bakongAccountID")),
                merchantName: try XCTUnwrap(string("merchantName")),
                merchantCity: try XCTUnwrap(string("merchantCity")),
                merchantID: try XCTUnwrap(string("merchantID")),
                acquiringBank: try XCTUnwrap(string("acquiringBank")),
                currency: currency,
                amount: amount,
                billNumber: string("billNumber"),
                storeLabel: string("storeLabel"),
                terminalLabel: string("terminalLabel"),
                mobileNumber: string("mobileNumber"),
                purposeOfTransaction: string("purposeOfTransaction"),
                languagePreference: string("languagePreference"),
                merchantNameAlternateLanguage: string("merchantNameAlternateLanguage"),
                merchantCityAlternateLanguage: string("merchantCityAlternateLanguage"),
                upiMerchantAccount: string("upiMerchantAccount"),
                expirationTimestamp: expirationTimestamp,
                merchantCategoryCode: string("merchantCategoryCode")
            ))
        }
        return Information(IndividualInfo(
            bakongAccountID: try XCTUnwrap(string("bakongAccountID")),
            merchantName: try XCTUnwrap(string("merchantName")),
            merchantCity: try XCTUnwrap(string("merchantCity")),
            accountInformation: string("accountInformation"),
            acquiringBank: string("acquiringBank"),
            currency: currency,
            amount: amount,
            billNumber: string("billNumber"),
            storeLabel: string("storeLabel"),
            terminalLabel: string("terminalLabel"),
            mobileNumber: string("mobileNumber"),
            purposeOfTransaction: string("purposeOfTransaction"),
            languagePreference: string("languagePreference"),
            merchantNameAlternateLanguage: string("merchantNameAlternateLanguage"),
            merchantCityAlternateLanguage: string("merchantCityAlternateLanguage"),
            upiMerchantAccount: string("upiMerchantAccount"),
            expirationTimestamp: expirationTimestamp,
            merchantCategoryCode: string("merchantCategoryCode")
        ))
    }
}

private extension KHQRNode {
    var json: Any {
        switch self {
        case .value(let value): return value
        case .template(let template): return template.mapValues(\.json)
        }
    }
}
