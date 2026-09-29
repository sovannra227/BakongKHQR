import Foundation

// Helpers that reproduce the JavaScript semantics the KHQR format depends on.
// Lengths and offsets in a KHQR string are counted in UTF-16 code units (JavaScript's
// `String.length`), not in Swift `Character`s, which matters for Khmer text.

extension String {
    /// JavaScript `String.prototype.length`.
    var jsLength: Int { utf16.count }

    /// JavaScript `String.prototype.slice(start, end)`. A `nil` bound stands for `NaN`/omitted.
    func jsSlice(_ start: Int?, _ end: Int?? = .none) -> String {
        let units = Array(utf16)
        let count = units.count

        func resolve(_ index: Int) -> Int {
            index < 0 ? max(count + index, 0) : min(index, count)
        }

        let from = resolve(start ?? 0)
        let to: Int
        switch end {
        case .none: to = count
        case .some(.none): to = 0
        case .some(.some(let value)): to = resolve(value)
        }
        guard from < to else { return "" }
        return String(decoding: units[from..<to], as: UTF16.self)
    }

    /// Matches the JavaScript regular expression `/^\d+$/`.
    var isJSNumeric: Bool {
        !isEmpty && utf16.allSatisfy { $0 >= 0x30 && $0 <= 0x39 }
    }
}

enum JS {
    private static let whitespace = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}"))

    /// JavaScript `parseInt(string)`. Returns `nil` for `NaN`.
    static func parseInt(_ string: String) -> Int? {
        var scalars = Substring(string.trimmingCharacters(in: whitespace)).unicodeScalars[...]
        var negative = false
        if let first = scalars.first, first == "-" || first == "+" {
            negative = first == "-"
            scalars = scalars.dropFirst()
        }

        var radix = 10
        let prefix = String(String.UnicodeScalarView(scalars.prefix(2))).lowercased()
        if prefix == "0x" {
            radix = 16
            scalars = scalars.dropFirst(2)
        }

        var result = 0
        var hasDigits = false
        for scalar in scalars {
            guard let digit = Character(scalar).hexDigitValue, digit < radix, scalar.isASCII else { break }
            hasDigits = true
            let (multiplied, overflowed) = result.multipliedReportingOverflow(by: radix)
            let (added, overflowedAdd) = multiplied.addingReportingOverflow(digit)
            if overflowed || overflowedAdd {
                result = Int.max
                break
            }
            result = added
        }
        guard hasDigits else { return nil }
        return negative ? -result : result
    }

    /// JavaScript `Number(string)`. Returns `.nan` when the string is not a numeric literal.
    static func number(_ string: String) -> Double {
        let trimmed = string.trimmingCharacters(in: whitespace)
        if trimmed.isEmpty { return 0 }

        switch trimmed {
        case "Infinity", "+Infinity": return .infinity
        case "-Infinity": return -.infinity
        default: break
        }

        let lowered = trimmed.lowercased()
        for (prefix, radix) in [("0x", 16), ("0o", 8), ("0b", 2)] where lowered.hasPrefix(prefix) {
            let digits = lowered.dropFirst(2)
            guard !digits.isEmpty, let value = UInt64(digits, radix: radix) else { return .nan }
            return Double(value)
        }

        guard let literal = normalizedDecimalLiteral(trimmed) else { return .nan }
        return Double(literal) ?? .nan
    }

    /// Validates `[+-]? (digits [. digits?]? | . digits) ([eE] [+-]? digits)?` and rewrites it
    /// into a form `Double.init` always accepts.
    private static func normalizedDecimalLiteral(_ string: String) -> String? {
        var rest = Substring(string)
        var sign = ""
        if let first = rest.first, first == "-" || first == "+" {
            sign = first == "-" ? "-" : ""
            rest = rest.dropFirst()
        }

        func takeDigits() -> Substring {
            let digits = rest.prefix { $0.isASCII && $0.isNumber }
            rest = rest.dropFirst(digits.count)
            return digits
        }

        let integer = takeDigits()
        var fraction = Substring()
        if rest.first == "." {
            rest = rest.dropFirst()
            fraction = takeDigits()
        }
        guard !integer.isEmpty || !fraction.isEmpty else { return nil }

        var exponent = ""
        if let marker = rest.first, marker == "e" || marker == "E" {
            rest = rest.dropFirst()
            var exponentSign = ""
            if let first = rest.first, first == "-" || first == "+" {
                exponentSign = String(first)
                rest = rest.dropFirst()
            }
            let digits = takeDigits()
            guard !digits.isEmpty else { return nil }
            exponent = "e\(exponentSign)\(digits)"
        }
        guard rest.isEmpty else { return nil }

        let integerPart = integer.isEmpty ? "0" : String(integer)
        let fractionPart = fraction.isEmpty ? "0" : String(fraction)
        return "\(sign)\(integerPart).\(fractionPart)\(exponent)"
    }

    /// JavaScript `String(number)` / `Number.prototype.toString()`.
    static func string(_ number: Double) -> String {
        if number.isNaN { return "NaN" }
        if number == 0 { return "0" }
        if number.isInfinite { return number < 0 ? "-Infinity" : "Infinity" }

        // Swift prints the shortest round-tripping digits, as JavaScript does; only the
        // layout differs, so take the digits and exponent and lay them out the JS way.
        let description = "\(abs(number))".lowercased()
        let parts = description.split(separator: "e", maxSplits: 1)
        let mantissa = parts[0].split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integer = String(mantissa[0])
        let fraction = mantissa.count > 1 ? String(mantissa[1]) : ""
        let exponent = parts.count > 1 ? Int(parts[1]) ?? 0 : 0

        var digits = Array(integer + fraction)
        // value = 0.d1d2...dk x 10^n
        var n = integer.count + exponent
        while let first = digits.first, first == "0" {
            digits.removeFirst()
            n -= 1
        }
        while let last = digits.last, last == "0" {
            digits.removeLast()
        }
        let k = digits.count

        let body: String
        if k <= n && n <= 21 {
            body = String(digits) + String(repeating: "0", count: n - k)
        } else if n > 0 && n <= 21 {
            body = String(digits[..<n]) + "." + String(digits[n...])
        } else if n > -6 && n <= 0 {
            body = "0." + String(repeating: "0", count: -n) + String(digits)
        } else {
            let e = n - 1
            let exponentPart = (e < 0 ? "e-" : "e+") + String(abs(e))
            body = k == 1
                ? String(digits) + exponentPart
                : String(digits[0]) + "." + String(digits[1...]) + exponentPart
        }
        return number < 0 ? "-" + body : body
    }
}

extension Date {
    /// JavaScript `Date.now()` for this instant.
    var jsMilliseconds: Double { (timeIntervalSince1970 * 1000).rounded(.down) }
}
