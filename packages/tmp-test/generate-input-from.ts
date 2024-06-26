import { bytesToBigInt, fromHex } from "@zk-email/helpers/dist/binary-format";
import { generateEmailVerifierInputs } from "@zk-email/helpers/dist/input-generators";
import fs from "fs";
import path from "path";

export const STRING_PRESELECTOR = "OKC certify that you are @";
export const STRING_PRESELECTOR_FROM = "\nfrom:";
export const STRING_PRESELECTOR_ADDRESS = "address is ";
export type CircuitInputs = {
  usernameIndex: string;
  evmAddressIndex: string;
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
  email: string | Buffer
): Promise<CircuitInputs> {
  const emailVerifierInputs = await generateEmailVerifierInputs(email, {
    shaPrecomputeSelector: STRING_PRESELECTOR,
  });
  console.log("emailVerifierInputs",JSON.stringify(emailVerifierInputs));

  const bodyRemaining = emailVerifierInputs.emailBody!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBuffer = Buffer.from(STRING_PRESELECTOR);
  const usernameIndex = Buffer.from(bodyRemaining).indexOf(selectorBuffer) + selectorBuffer.length;
  console.log("usernameIndex",usernameIndex.toString());

  const selectorBufferAddress = Buffer.from(STRING_PRESELECTOR_ADDRESS);
  const evmAddressIndex = Buffer.from(bodyRemaining).indexOf(selectorBufferAddress) + selectorBufferAddress.length;
  console.log("evmAddressIndex",evmAddressIndex.toString());

  const header = emailVerifierInputs.emailHeader!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBufferFrom = Buffer.from(STRING_PRESELECTOR_FROM);
  console.log("selectorBufferFrom",selectorBufferFrom);
  let fromEmailIndex = Buffer.from(header).indexOf(selectorBufferFrom);
  console.log("fromEmailIndex", fromEmailIndex.toString());
  if (fromEmailIndex !== -1) {
      fromEmailIndex += selectorBufferFrom.length;
      // Continue searching for '<' symbol
      let foundIndex = -1;
      for (let i = fromEmailIndex; i < header.length; i++) {
          if (header[i] === '<'.charCodeAt(0)) {
              foundIndex = i;
              break;
          }
      }

      if (foundIndex !== -1) {
          fromEmailIndex = foundIndex + 1;
          console.log("final fromEmailIndex:", fromEmailIndex);
      } else {
          throw new Error("Could not find '<' after fromEmailIndex");
      }
  }else{
    throw new Error("fromEmailIndex not found");
  }
  

  const circuitInputs = {
    ...emailVerifierInputs,
    usernameIndex: usernameIndex.toString(),
    evmAddressIndex : evmAddressIndex.toString(),
    fromEmailIndex : fromEmailIndex.toString(),
  };
  // fs.writeFileSync(
  //   path.join(OUTPUT_DIR, "input.json"),
  //   JSON.stringify(circuitInputs, null, 2)
  // );
  return circuitInputs;
}