/// A tag-length-value element of a KHQR string.
struct TLV {
    let tag: String
    let value: String

    var encoded: String {
        let length = value.jsLength
        return tag + (length < 10 ? "0\(length)" : "\(length)") + value
    }
}

/// The leading element of a KHQR string together with what follows it.
struct TLVCut {
    let tag: String
    /// `nil` when the two length characters are not a number.
    let length: Int?
    let value: String
    let rest: String

    init(_ string: String) {
        tag = string.jsSlice(0, 2)
        length = JS.parseInt(string.jsSlice(2, 4))
        value = string.jsSlice(4, .some(length.map { 4 + $0 }))
        rest = string.jsSlice(length.map { 4 + $0 })
    }
}
