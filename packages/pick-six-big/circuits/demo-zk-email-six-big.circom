pragma circom 2.1.5;

include "@zk-email/zk-regex-circom/circuits/common/from_addr_regex.circom";
include "@zk-email/circuits/email-verifier.circom";
include "@zk-email/circuits/utils/regex.circom";
include "../../regex/body-username-regex.circom";
include "../../regex/evm-address-regex.circom";
include "../../regex/eth-amount-regex.circom";

/// @title ZKEmail
/// @notice Circuit to verify input email matches Twitter password reset email, and extract the username
/// @param maxHeadersLength Maximum length for the email header.
/// @param maxBodyLength Maximum length for the email body.
/// @param n Number of bits per chunk the RSA key is split into. Recommended to be 121.
/// @param k Number of chunks the RSA key is split into. Recommended to be 17.
/// @param exposeFrom Flag to expose the from email address (not necessary for verification). We don't expose `to` as its not always signed.
/// @input emailHeader Email headers that are signed (ones in `DKIM-Signature` header) as ASCII int[], padded as per SHA-256 block size.
/// @input emailHeaderLength Length of the email header including the SHA-256 padding.
/// @input pubkey RSA public key split into k chunks of n bits each.
/// @input signature RSA signature split into k chunks of n bits each.
/// @input emailBody Email body after the precomputed SHA as ASCII int[], padded as per SHA-256 block size.
/// @input emailBodyLength Length of the email body including the SHA-256 padding.
/// @input bodyHashIndex Index of the body hash `bh` in the emailHeader.
/// @input precomputedSHA Precomputed SHA-256 hash of the email body till the bodyHashIndex.
/// @input usernameIndex Index of the Twitter username in the email body.
/// @output pubkeyHash Poseidon hash of the pubkey - Poseidon(n/2)(n/2 chunks of pubkey with k*2 bits per chunk).
template ZKEmail(maxHeadersLength, maxBodyLength, n, k, exposeFrom) {
    assert(exposeFrom < 2);

    signal input emailHeader[maxHeadersLength];
    signal input emailHeaderLength;
    signal input pubkey[k];
    signal input signature[k];
    signal input emailBody[maxBodyLength];
    signal input emailBodyLength;
    signal input bodyHashIndex;
    signal input precomputedSHA[32];
    signal input usernameIndex;
    signal input evmAddressIndex;
    signal input amountIndex;


    signal output pubkeyHash;
    signal output username;
    signal output evmAddress;
    signal output amount;


    component EV = EmailVerifier(maxHeadersLength, maxBodyLength, n, k, 0);
    EV.emailHeader <== emailHeader;
    EV.pubkey <== pubkey;
    EV.signature <== signature;
    EV.emailHeaderLength <== emailHeaderLength;
    EV.bodyHashIndex <== bodyHashIndex;
    EV.precomputedSHA <== precomputedSHA;
    EV.emailBody <== emailBody;
    EV.emailBodyLength <== emailBodyLength;

    pubkeyHash <== EV.pubkeyHash;


    // FROM HEADER REGEX: 736,553 constraints
    if (exposeFrom) {
        signal input fromEmailIndex;

        signal (fromEmailFound, fromEmailReveal[maxHeadersLength]) <== FromAddrRegex(maxHeadersLength)(emailHeader);
        fromEmailFound === 1;

        var maxEmailLength = 255;

        signal output fromEmailAddrPacks[9] <== PackRegexReveal(maxHeadersLength, maxEmailLength)(fromEmailReveal, fromEmailIndex);
    }


    // Username REGEX: 328,044 constraints
    // This computes the regex states on each character in the email body. For other apps, this is the
    // section that you want to swap out via using the zk-regex library.
    signal (usernameFound, usernameReveal[maxBodyLength]) <== BodyUserNameRegex(maxBodyLength)(emailBody);
    usernameFound === 1;

    // Pack the username to int
    var maxUsernameLength = 21;
    signal usernamePacks[1] <== PackRegexReveal(maxBodyLength, maxUsernameLength)(usernameReveal, usernameIndex);

    // Username will fit in one field element, so we take the first item from the packed array.
    username <== usernamePacks[0];

    signal (evmAddressFound, evmAddressReveal[maxBodyLength]) <== EVMAddressRegex(maxBodyLength)(emailBody);
    evmAddressFound === 1;

    // Pack the EVM address to int
    var maxEVMAddressLength = 42;
    signal evmAddressPacks[2] <== PackRegexReveal(maxBodyLength, maxEVMAddressLength)(evmAddressReveal, evmAddressIndex);

    // EVM address will fit in two field elements, so we take the first two items from the packed array.
    evmAddress <== evmAddressPacks[0] + evmAddressPacks[1];

    signal (amountFound, amountReveal[maxBodyLength]) <== ETHAmountRegex(maxBodyLength)(emailBody);
    amountFound === 1;

    // Pack the amount to int
    var maxAmountLength = 21;
    signal amountPacks[1] <== PackRegexReveal(maxBodyLength, maxAmountLength)(amountReveal, amountIndex);

    // Amount will fit in one field element, so we take the first item from the packed array.
    amount <== amountPacks[0];



    // Pack the EVM address to int
    signal evmAddressPacksAddition[2] <== PackRegexReveal(maxBodyLength, maxEVMAddressLength)(evmAddressReveal, evmAddressIndex);

    // EVM address will fit in two field elements, so we take the first two items from the packed array.
    signal output evmAddress1 <== evmAddressPacksAddition[0] + evmAddressPacksAddition[1];

    signal (amountFoundAddition, amountRevealAddition[maxBodyLength]) <== ETHAmountRegex(maxBodyLength)(emailBody);
    amountFoundAddition === 1;

    // Pack the amount to int
    signal amountPacksAddition[1] <== PackRegexReveal(maxBodyLength, maxAmountLength)(amountReveal, amountIndex);

    // Amount will fit in one field element, so we take the first item from the packed array.
    signal output amount1 <== amountPacksAddition[0];
}


// component main = ZKEmail(1024, 1536, 121, 17, 0);
// component main = ZKEmail(1024, 49152, 121, 17, 1);
component main = ZKEmail(1024, 12288, 121, 17, 1);
