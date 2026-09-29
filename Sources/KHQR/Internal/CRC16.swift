/// CRC-16/CCITT-FALSE (polynomial 0x1021, initial value 0xFFFF) over the UTF-8 bytes of a string.
enum CRC16 {
    private static let table: [UInt16] = (0..<256).map { index in
        var crc = UInt16(index) << 8
        for _ in 0..<8 {
            crc = crc & 0x8000 != 0 ? (crc << 1) ^ 0x1021 : crc << 1
        }
        return crc
    }

    /// Returns the checksum as four uppercase hexadecimal digits.
    static func checksum(_ string: String) -> String {
        var crc: UInt16 = 0xFFFF
        for byte in string.utf8 {
            let index = Int((UInt16(byte) ^ (crc >> 8)) & 0xFF)
            crc = table[index] ^ (crc << 8)
        }
        let hex = String(crc, radix: 16, uppercase: true)
        return String(repeating: "0", count: 4 - hex.count) + hex
    }
}
