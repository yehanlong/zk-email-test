import { bytesToBigInt, fromHex } from "@zk-email/helpers/dist/binary-format";
import { generateEmailVerifierInputs } from "@zk-email/helpers/dist/input-generators";
import fs from "fs";
import path from "path";


export const STRING_PRESELECTOR = "OKC certify that you are @";
export type CircuitInputs = {
  usernameIndex: string;
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
  output_dir: string
): Promise<CircuitInputs> {
  const email = Buffer.from(fs.readFileSync(email_dir, "utf8"));
  const emailVerifierInputs = await generateEmailVerifierInputs(email, {
    shaPrecomputeSelector: STRING_PRESELECTOR,
  });
  // console.log("emailVerifierInputs",JSON.stringify(emailVerifierInputs));

  const bodyRemaining = emailVerifierInputs.emailBody!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBuffer = Buffer.from(STRING_PRESELECTOR);
  const usernameIndex = Buffer.from(bodyRemaining).indexOf(selectorBuffer) + selectorBuffer.length;
  // console.log("usernameIndex",usernameIndex.toString());
  const circuitInputs =  {
    ...emailVerifierInputs,
    usernameIndex: usernameIndex.toString(),
  };
  fs.writeFileSync(
    path.join(output_dir, "input.json"),
    JSON.stringify(circuitInputs, null, 2)
  );
  // console.log("Inputs written to", path.join(output_dir, "input.json"));
  return circuitInputs;
}