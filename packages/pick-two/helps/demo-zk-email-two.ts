import { program } from "commander";
import fs from "fs";
import path from "path";
import { generateInputs } from "./generate-input-two";
const snarkjs = require("snarkjs");

program
  .requiredOption("--email-file <string>", "Path to email file")
  .option("--circuit-name <string>", "circuit-name")
  .option("--build-dir <string>", "build-dir")
  .option("--output-dir <string>", "output-dir")
  .option("--silent", "No console logs");

program.parse();
const args = program.opts();

var CIRCUIT_NAME = args.circuitName;
var BUILD_DIR = args.buildDir;
var OUTPUT_DIR = args.outputDir;
if (CIRCUIT_NAME == null) {
  CIRCUIT_NAME = "demo-zk-email-two";
  log("No CIRCUIT_NAME provided, using demo-zk-email-two");
}
if (BUILD_DIR == null) {
  BUILD_DIR = path.join(__dirname, "../build-two");
  log("No BUILD_DIR provided, using /build-two");
}
if (OUTPUT_DIR == null) {
  OUTPUT_DIR = path.join(__dirname, "../proofs-two");
  log("No OUTPUT_DIR provided, using /proofs-two");
}

function log(...message: any) {
  if (!args.silent) {
    console.log(...message);
  }
}
const logger = { log, error: log, warn: log, debug: log };

async function generate() {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR);
  }

  if (!fs.existsSync(args.emailFile)) {
    throw new Error("--email file path arg must end with .json");
  }
  log("Generating input and proof for:", args.emailFile);
  
  const circuitInputs = await generateInputs(args.emailFile,OUTPUT_DIR);

  log("\n\nGenerated Inputs:", circuitInputs, "\n\n");

  // Generate proof
  const startTime = Date.now();
  log(`Proof generate start time: `,startTime);
  const wasmPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm`)
  const zkeyPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}-final.zkey`)
  log("Generating proof zkeyPath:",zkeyPath,",wasmPath:",wasmPath);
  const circuitInputsCopy = JSON.parse(JSON.stringify(circuitInputs));
  const {
      proof,
      publicSignals
  } = await snarkjs.groth16.fullProve(circuitInputsCopy, wasmPath, zkeyPath);
  const endTime = Date.now();
  const proveTime = endTime - startTime;
  log(`Proof generate end time:`,endTime,`,cost:`,`${proveTime} milliseconds`);
  fs.writeFileSync(
    path.join(OUTPUT_DIR, "proof.json"),
    JSON.stringify(proof, null, 2)
  );
  log("Proof written to", path.join(OUTPUT_DIR, "proof.json"));

  fs.writeFileSync(
    path.join(OUTPUT_DIR, "public.json"),
    JSON.stringify(publicSignals, null, 2)
  );
  log("Public Inputs written to", path.join(OUTPUT_DIR, "public.json"));

  const vkey = JSON.parse(fs.readFileSync(path.join(BUILD_DIR, `${CIRCUIT_NAME}.vkey.json`)).toString());
  const proofVerified = await snarkjs.groth16.verify(
    vkey,
    publicSignals,
    proof
  );
  if (proofVerified) {
    log("Proof Verified");
  } else {
    throw new Error("Proof Verification Failed");
  }

  process.exit(0);
}

generate().catch((err) => {
  console.error("Error generating proof", err);
  process.exit(1);
});
