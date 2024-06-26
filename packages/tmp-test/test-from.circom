pragma circom 2.1.5;

include "@zk-email/zk-regex-circom/circuits/regex_helpers.circom";
include "@zk-email/zk-regex-circom/circuits/common/from_all_regex.circom";
include "@zk-email/zk-regex-circom/circuits/common/email_addr_regex.circom";
include "@zk-email/zk-regex-circom/circuits/common/email_addr_with_name_regex.circom";
include "@zk-email/circuits/utils/regex.circom";


template TestFromAddrRegex(msg_bytes) {
	signal input msg[msg_bytes];
	signal output out;
	signal output reveal0[msg_bytes];

	signal fromOut;
	signal fromReveal[msg_bytes];
	(fromOut, fromReveal) <== FromAllRegex(msg_bytes)(msg);
	fromOut === 1;

	signal emailNameOut;
	signal emailNameReveal[msg_bytes];
	(emailNameOut, emailNameReveal) <== EmailAddrWithNameRegex(msg_bytes)(fromReveal);

	signal emailAddrOut;
	signal emailAddrReveal[msg_bytes];
	(emailAddrOut, emailAddrReveal) <== EmailAddrRegex(msg_bytes)(fromReveal);

	out <== MultiOR(2)([emailNameOut, emailAddrOut]);
	for(var i=0; i<msg_bytes; i++) {
		reveal0[i] <== emailNameOut * (emailNameReveal[i] - emailAddrReveal[i]) + emailAddrReveal[i];
	}
}

template TestCheckFrom(maxHeadersLength){

    signal input fromEmailIndex;    
    signal input msg[maxHeadersLength];
    
    signal (fromEmailFound, fromEmailReveal[maxHeadersLength]) <== TestFromAddrRegex(maxHeadersLength)(msg);
    fromEmailFound === 1;

    var maxEmailLength = 255;

    signal output fromEmailAddrPacks[9] <== PackRegexReveal(maxHeadersLength, maxEmailLength)(fromEmailReveal, fromEmailIndex);
}

component main = TestCheckFrom(1024);

