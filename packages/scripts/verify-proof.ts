import fs from "fs";
import path from "path";
const snarkjs = require("zk-email-snarkjs");

const CIRCUIT_NAME = "demo-zk-email";
const BUILD_DIR = path.join(__dirname, "../build");
const OUTPUT_DIR = path.join(__dirname, "../proofs");

async function verifier() {

    const proofPath = path.join(OUTPUT_DIR, "proof.json");
    const publicPath = path.join(OUTPUT_DIR, "public.json");
  
    const proof = JSON.parse(fs.readFileSync(proofPath, "utf-8"));
    const publicSignals = JSON.parse(fs.readFileSync(publicPath, "utf-8"));

    const vkey = JSON.parse(fs.readFileSync(path.join(BUILD_DIR, `/artifacts/${CIRCUIT_NAME}.vkey.json`)).toString());
    const proofVerified = await snarkjs.groth16.verify(
      vkey,
      publicSignals,
      proof
    );
    if (proofVerified) {
      console.log("Proof Verified");
    } else {
      throw new Error("Proof Verification Failed");
    }
  
    process.exit(0);
}

verifier().catch((err) => {
    console.error("Error generating proof", err);
    process.exit(1);
  });