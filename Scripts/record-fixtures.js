#!/usr/bin/env node
// Records the behaviour of the Bakong KHQR JavaScript SDK as test vectors for this package.
//
// It runs the test files of the JavaScript SDK with a stubbed test runner, notes every call
// they make to the SDK, then replays each call under fixed clocks and writes what the SDK
// returned.
//
// Usage: node Scripts/record-fixtures.js <path to bakong-khqr> [output file]

const fs = require("fs");
const path = require("path");

const sdkPath = process.argv[2];
if (!sdkPath) {
    console.error("Usage: node Scripts/record-fixtures.js <path to bakong-khqr> [output file]");
    process.exit(1);
}
const sdkRoot = path.resolve(sdkPath);
const output = path.resolve(
    process.argv[3] || path.join(__dirname, "../Tests/KHQRTests/Fixtures/vectors.json")
);

// The SDK reads the time through Date.now() only.
const CLOCKS = [1700000000000, 1800000000000];
let now = CLOCKS[0];
Date.now = () => now;

const { BakongKHQR } = require(path.join(sdkRoot, "src"));

const original = {
    generateIndividual: BakongKHQR.prototype.generateIndividual,
    generateMerchant: BakongKHQR.prototype.generateMerchant,
    decode: BakongKHQR.decode,
    decodeNonKhqr: BakongKHQR.decodeNonKhqr,
    verify: BakongKHQR.verify,
};

const calls = [];
const record = (kind, fn) =>
    function (input) {
        calls.push({ kind, input });
        return fn.call(this, input);
    };

BakongKHQR.prototype.generateIndividual = record("generateIndividual", original.generateIndividual);
BakongKHQR.prototype.generateMerchant = record("generateMerchant", original.generateMerchant);
BakongKHQR.decode = record("decode", original.decode);
BakongKHQR.decodeNonKhqr = record("decodeNonKhqr", original.decodeNonKhqr);
BakongKHQR.verify = record("verify", original.verify);

// A test runner that runs every test body and accepts every expectation.
const anything = new Proxy(function () {}, {
    get: () => anything,
    apply: () => anything,
});
const run = (_, body) => {
    try {
        body();
    } catch (error) {}
};
global.test = global.it = run;
global.describe = run;
global.expect = anything;
for (const hook of ["beforeAll", "beforeEach", "afterAll", "afterEach"]) global[hook] = () => {};

// Tests of the Bakong Open API need the network.
const skippedFiles = ["bakongAccountExist.test.js", "deepLink.test.js"];

function testFiles(directory) {
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
        const file = path.join(directory, entry.name);
        if (entry.isDirectory()) return testFiles(file);
        return entry.name.endsWith(".test.js") && !skippedFiles.includes(entry.name) ? [file] : [];
    });
}

for (const file of testFiles(path.join(sdkRoot, "test")).sort()) require(file);

// Cases the tests of the SDK leave out.
const { IndividualInfo, MerchantInfo } = require(path.join(sdkRoot, "src"));
const expiry = CLOCKS[0] + 60 * 1000;
const extras = [
    { amount: 1.5, currency: 840, expirationTimestamp: expiry },
    { amount: 0.1, currency: 840, expirationTimestamp: expiry },
    { amount: 10.25, currency: 840, expirationTimestamp: expiry },
    { amount: 100, currency: 840, expirationTimestamp: expiry },
    { amount: 1.005, currency: 840, expirationTimestamp: expiry },
    { amount: 0.1 + 0.2, currency: 840, expirationTimestamp: expiry },
    { amount: 0.0000001, currency: 840, expirationTimestamp: expiry },
    { amount: 0.000001, currency: 840, expirationTimestamp: expiry },
    { amount: 1234567890.12, currency: 840, expirationTimestamp: expiry },
    { amount: 12345678901.12, currency: 840, expirationTimestamp: expiry },
    { amount: -5, currency: 840, expirationTimestamp: expiry },
    { amount: 1e21, currency: 116, expirationTimestamp: expiry },
    { amount: 1234567890123, currency: 116, expirationTimestamp: expiry },
    { amount: 12345678901234, currency: 116, expirationTimestamp: expiry },
    { amount: 100.5, currency: 116, expirationTimestamp: expiry },
    { amount: 5000, currency: 116 },
    { amount: 5000, currency: 116, expirationTimestamp: 0 },
    { amount: 5000, currency: 116, expirationTimestamp: 17000000 },
    { amount: 5000, currency: 116, expirationTimestamp: -170000000000 },
    { amount: 0, currency: 840 },
    { currency: 978 },
    { currency: 0 },
    { currency: 1000 },
    { upiMerchantAccount: "1234567890123456", currency: 116 },
    { upiMerchantAccount: "1234567890123456", currency: 840 },
    { upiMerchantAccount: "1".repeat(100), currency: 116 },
    { languagePreference: "km", merchantNameAlternateLanguage: "ចន ស្មីត", merchantCityAlternateLanguage: "សៀមរាប" },
    { languagePreference: "km", merchantNameAlternateLanguage: "ហាងកាហ្វេ ខ្លាំង ភ្នំពេញ សាខាទី១" },
    { languagePreference: "km" },
    { merchantNameAlternateLanguage: "ចន ស្មីត" },
    { merchantCityAlternateLanguage: "សៀមរាប" },
    { storeLabel: "ហាងកាហ្វេ", billNumber: "វិក្កយបត្រ #១", terminalLabel: "😀 Counter" },
    { purposeOfTransaction: "Payment for coffee", mobileNumber: "85512345678" },
    { accountInformation: "012345678", acquiringBank: "Dev Bank" },
    { accountInformation: "1".repeat(33) },
    { merchantCategoryCode: "0000" },
    { merchantCategoryCode: "12a4" },
    { merchantCategoryCode: "12345" },
];
const names = [
    ["john_smith@devb", "John Smith", "Phnom Penh"],
    ["john_smith@devb", "ចន ស្មីត", "ភ្នំពេញ"],
    ["john_smith@devb", "John Smith", ""],
    ["a@b@c", "John Smith", "Siem Reap"],
];
for (const optional of extras) {
    for (const [account, name, city] of names.slice(0, optional.currency === undefined ? 4 : 1)) {
        const khqr = new BakongKHQR();
        khqr.generateIndividual(new IndividualInfo(account, name, city, { ...optional }));
        khqr.generateMerchant(new MerchantInfo(account, name, city, "123456", "Dev Bank", { ...optional }));
    }
}
new BakongKHQR().generateMerchant(new MerchantInfo("john_smith@devb", "John Smith", "Phnom Penh", "", "Dev Bank"));
new BakongKHQR().generateMerchant(new MerchantInfo("john_smith@devb", "John Smith", "Phnom Penh", "123456", ""));
new BakongKHQR().generateMerchant(new MerchantInfo("john_smith@devb", "John Smith", "Phnom Penh", "1".repeat(33), "Dev Bank"));

// Every KHQR generated so far is also decoded and verified.
for (const call of calls.slice()) {
    if (call.kind !== "generateIndividual" && call.kind !== "generateMerchant") continue;
    let response;
    try {
        response = original[call.kind].call(new BakongKHQR(), call.input);
    } catch (error) {
        continue;
    }
    const qr = response && response.data && response.data.qr;
    if (typeof qr !== "string") continue;
    calls.push({ kind: "verify", input: qr }, { kind: "decode", input: qr }, { kind: "decodeNonKhqr", input: qr });
    // The same KHQR with a tampered value and a recomputed checksum, and cut short.
    const crc16 = require(path.join(sdkRoot, "src/helper/crc16"));
    const tampered = qr.slice(0, -4).replace("5802KH", "5804KHMR");
    calls.push({ kind: "verify", input: tampered + crc16(tampered) });
    calls.push({ kind: "verify", input: qr.slice(0, -1) }, { kind: "decode", input: qr.slice(0, 40) });
}

const REQUIRED = ["bakongAccountID", "merchantName", "merchantCity"];
const REQUIRED_MERCHANT = ["merchantID", "acquiringBank"];
const OPTIONAL = [
    "accountInformation",
    "acquiringBank",
    "billNumber",
    "storeLabel",
    "terminalLabel",
    "mobileNumber",
    "purposeOfTransaction",
    "languagePreference",
    "merchantNameAlternateLanguage",
    "merchantCityAlternateLanguage",
    "upiMerchantAccount",
    "merchantCategoryCode",
];

// The details as the Swift package takes them, or null when they have no Swift counterpart
// (such as an amount given as a string).
function serialize(info, isMerchant) {
    const result = {};
    const required = isMerchant ? REQUIRED.concat(REQUIRED_MERCHANT) : REQUIRED;

    for (const field of required) {
        const value = info[field];
        if (value === undefined || value === null) result[field] = "";
        else if (typeof value === "string" || typeof value === "number") result[field] = String(value);
        else return null;
    }
    for (const field of OPTIONAL) {
        if (required.includes(field)) continue;
        const value = info[field];
        if (value === undefined || value === null || value === "" || value === 0) continue;
        if (typeof value === "string" || typeof value === "number") result[field] = String(value);
        else return null;
    }

    if (typeof info.currency !== "number" || !Number.isInteger(info.currency)) return null;
    result.currency = info.currency;

    if (info.amount !== undefined && info.amount !== null) {
        if (typeof info.amount !== "number" || !Number.isFinite(info.amount)) return null;
        result.amount = info.amount;
    }
    if (info.expirationTimestamp !== undefined && info.expirationTimestamp !== null) {
        if (!Number.isSafeInteger(info.expirationTimestamp)) return null;
        result.expirationTimestamp = info.expirationTimestamp;
    }
    return result;
}

function generateOutput(response) {
    if (response && response.status && response.status.errorCode != null)
        return { errorCode: response.status.errorCode };
    if (response && response.data && typeof response.data.qr === "string")
        return { qr: response.data.qr, md5: response.data.md5 };
    // The SDK failed with something other than a KHQR error.
    return { crash: true };
}

// Why verify() turns a string down, which it does not report itself: the code of the KHQR
// error, "crash" for any other failure, or null when the string is valid.
function invalidReason(qr) {
    const crc16 = require(path.join(sdkRoot, "src/helper/crc16"));
    const validate = require(path.join(sdkRoot, "src/controller/decodeValidation"));

    if (!/6304[A-Fa-f0-9]{4}$/.test(qr)) return 8;
    if (crc16(qr.slice(0, -4)) != qr.slice(-4).toUpperCase() || qr.length < 12) return 8;
    try {
        validate(qr);
        return null;
    } catch (error) {
        return error && error.status ? error.status.errorCode : "crash";
    }
}

const vectors = [];
const seen = new Set();
let skipped = 0;

function add(vector) {
    const key = JSON.stringify([vector.kind, vector.now, vector.input]);
    if (seen.has(key)) return;
    seen.add(key);
    vectors.push(vector);
}

for (const call of calls) {
    if (call.kind === "generateIndividual" || call.kind === "generateMerchant") {
        const isMerchant = call.kind === "generateMerchant";
        const input = call.input && serialize(call.input, isMerchant);
        if (!input) {
            skipped++;
            continue;
        }
        for (const clock of CLOCKS) {
            now = clock;
            let result;
            try {
                result = generateOutput(original[call.kind].call(new BakongKHQR(), call.input));
            } catch (error) {
                result = { crash: true };
            }
            add({ kind: call.kind, now, input, output: result });
        }
    } else if (typeof call.input !== "string") {
        skipped++;
    } else if (call.kind === "verify") {
        for (const clock of CLOCKS) {
            now = clock;
            add({
                kind: "verify",
                now,
                input: call.input,
                output: original.verify.call(BakongKHQR, call.input).isValid,
                reason: invalidReason(call.input),
            });
        }
    } else {
        now = CLOCKS[0];
        try {
            const data = original[call.kind].call(BakongKHQR, call.input).data;
            add({ kind: call.kind, now, input: call.input, output: data });
        } catch (error) {
            skipped++;
        }
    }
}

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, JSON.stringify(vectors, null, 1) + "\n");

const count = {};
for (const vector of vectors) count[vector.kind] = (count[vector.kind] || 0) + 1;
console.log(`Recorded ${vectors.length} vectors to ${output}`);
console.log(count);
console.log(`Skipped ${skipped} calls with no Swift counterpart`);
