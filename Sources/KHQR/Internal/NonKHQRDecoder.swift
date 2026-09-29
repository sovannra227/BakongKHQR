enum NonKHQRDecoder {
    /// Decodes any EMV QR string into its tags, expanding the templates (tags 26-51, 62, 64
    /// and 80-99) one level, and tags 50-99 of the additional data template (62) a second level.
    static func decode(_ qr: String) -> [String: KHQRNode] {
        var result: [String: KHQRNode] = [:]

        for (tag, value) in elements(of: qr) {
            result[tag] = .value(value)

            guard isTemplate(tag), value.jsLength >= 6 else { continue }

            var template: [String: KHQRNode] = [:]
            for (subTag, subValue) in elements(of: value) {
                var nested: [String: KHQRNode] = [:]
                if tag == EMV.additionalData, let number = Int(subTag), (50...99).contains(number) {
                    for (nestedTag, nestedValue) in elements(of: subValue) {
                        nested[nestedTag] = .value(nestedValue)
                    }
                }
                template[subTag] = nested.isEmpty ? .value(subValue) : .template(nested)
            }
            if !template.isEmpty {
                result[tag] = .template(template)
            }
        }
        return result
    }

    private static func isTemplate(_ tag: String) -> Bool {
        if tag == EMV.additionalData || tag == EMV.merchantInformationLanguageTemplate { return true }
        guard let number = Int(tag) else { return false }
        return (26...51).contains(number) || (80...99).contains(number)
    }

    /// The well-formed elements at the start of a string, in order.
    private static func elements(of string: String) -> [(tag: String, value: String)] {
        var elements: [(tag: String, value: String)] = []
        var remaining = string
        repeat {
            let cut = TLVCut(remaining)
            guard cut.tag.isJSNumeric, let length = cut.length, length == cut.value.jsLength else { break }
            elements.append((cut.tag, cut.value))
            guard cut.rest.jsLength < remaining.jsLength else { break }
            remaining = cut.rest
        } while !remaining.isEmpty
        return elements
    }
}
