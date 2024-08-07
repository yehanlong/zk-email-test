import { bytesToBigInt, fromHex } from "@zk-email/helpers/dist/binary-format";
import { generateEmailVerifierInputs } from "@zk-email/helpers/dist/input-generators";
import fs from "fs";
import path from "path";

export const STRING_PRESELECTOR = "OKC certify that you are @";
export const STRING_PRESELECTOR_FROM = "\nfrom:";
export const STRING_PRESELECTOR_ADDRESS = "address is";
export const STRING_PRESELECTOR_AMOUNT = "a transfer of ";
export type CircuitInputs = {
  usernameIndex: string;
  evmAddressIndex: string;
  amountIndex: string;
  fromEmailIndex: string;
  emailHeader: string[];
  emailHeaderLength: string;
  pubkey: string[];
  signature: string[];
  emailBody?: string[] | undefined;
  emailBodyLength?: string | undefined;
  precomputedSHA?: string[] | undefined;
  bodyHashIndex?: string | undefined;
};

export async function generateInputs(
  email_dir: string,
  output_dir: string,
): Promise<CircuitInputs> {
  const email = Buffer.from(fs.readFileSync(email_dir, "utf8"));
  const emailVerifierInputs = await generateEmailVerifierInputs(email, {
    shaPrecomputeSelector: STRING_PRESELECTOR,
    maxBodyLength: 12288,
  });
  // console.log("emailVerifierInputs",JSON.stringify(emailVerifierInputs));

  const bodyRemaining = emailVerifierInputs.emailBody!.map((c) => Number(c)); // Char array to Uint8Array
  const bodyRemainingString = String.fromCharCode(...bodyRemaining);
  // console.log("bodyRemainingString:", bodyRemainingString);

  const selectorBuffer = Buffer.from(STRING_PRESELECTOR);
  var usernameIndex = Buffer.from(bodyRemaining).indexOf(selectorBuffer);
  if (usernameIndex !== -1) {
    usernameIndex += selectorBuffer.length;
    // console.log("usernameIndex",usernameIndex.toString());
  } else {
    throw new Error("usernameIndex not found");
  }
  const bodyRemainingString1 = String.fromCharCode(...bodyRemaining);
  const selectorBufferAddress = Buffer.from(STRING_PRESELECTOR_ADDRESS);
  var evmAddressIndex = Buffer.from(bodyRemaining).indexOf(
    selectorBufferAddress,
  );
  if (evmAddressIndex !== -1) {
    evmAddressIndex = evmAddressIndex + selectorBufferAddress.length + 2;
    // console.log("evmAddressIndex",evmAddressIndex.toString());
  } else {
    throw new Error("evmAddressIndex not found");
  }

  const selectorBufferAmount = Buffer.from(STRING_PRESELECTOR_AMOUNT);
  var amountIndex = Buffer.from(bodyRemaining).indexOf(selectorBufferAmount);
  if (amountIndex !== -1) {
    amountIndex = amountIndex + selectorBufferAmount.length + 4;
    // console.log("amountIndex",amountIndex.toString());
  } else {
    throw new Error("amountIndex not found");
  }

  const header = emailVerifierInputs.emailHeader!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBufferFrom = Buffer.from(STRING_PRESELECTOR_FROM);
  let fromEmailIndex = Buffer.from(header).indexOf(selectorBufferFrom);
  // console.log("fromEmailIndex", fromEmailIndex.toString());
  if (fromEmailIndex !== -1) {
    fromEmailIndex += selectorBufferFrom.length;
    // Continue searching for '<' symbol
    let foundIndex = -1;
    for (let i = fromEmailIndex; i < header.length; i++) {
      if (header[i] === "<".charCodeAt(0)) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex !== -1) {
      fromEmailIndex = foundIndex + 1;
      // console.log("final fromEmailIndex:", fromEmailIndex);
    } else {
      throw new Error("Could not find '<' after fromEmailIndex");
    }
  } else {
    throw new Error("fromEmailIndex not found");
  }

  const circuitInputs = {
    ...emailVerifierInputs,
    usernameIndex: usernameIndex.toString(),
    evmAddressIndex: evmAddressIndex.toString(),
    fromEmailIndex: fromEmailIndex.toString(),
    amountIndex: amountIndex.toString(),
  };
  fs.writeFileSync(
    path.join(output_dir, "input.json"),
    JSON.stringify(circuitInputs, null, 2),
  );
  return circuitInputs;
}
