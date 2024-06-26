import { program } from "commander";
// import { zKey } from "snarkjs";
import fs from "fs";
import path from "path";
import pako from "pako";
const snarkjs = require("zk-email-snarkjs");

program
  .option("--zkey-entropy <string>", "zkey-entropy")
  .option("--zkey-beacon <string>", "zkey-beacon")
  .option("--circuit-name <string>", "circuit-name")
  .option("--working-dir <string>", "working-dir")
  .option("--build-dir <string>", "build-dir")
  .option("--silent", "No console logs");
program.parse();
const args = program.opts();

var CIRCUIT_NAME = args.circuitName;
var parentDir = path.resolve(__dirname, '..');
var workingDir = path.join (parentDir, args.workingDir);
var BUILD_DIR = path.join(workingDir, args.buildDir);;
log("BUILD_DIR", BUILD_DIR);
var SILENT = args.silent;
var ZKEY_ENTROPY = args.zkeyEntropy;
var ZKEY_BEACON = args.zkeyBeacon;
if (ZKEY_ENTROPY == null) {
  log("No entropy provided, using `dev`");
  ZKEY_ENTROPY = "dev";
}
if (ZKEY_BEACON == null) {
  ZKEY_BEACON =
    "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
  log("No ZKEY_BEACON provided, using default");
}

if (CIRCUIT_NAME == null) {
  CIRCUIT_NAME = "demo-zk-email-one";
  log("No CIRCUIT_NAME provided, using demo-zk-email-one");
}
if (BUILD_DIR == null) {
  BUILD_DIR = path.join(process.cwd(), "../build-one");
  log("No BUILD_DIR provided, using /build-one");
}


const PHASE1_PATH = path.join(BUILD_DIR, "../../powersOfTau28_hez_final_22.ptau");
console.log(PHASE1_PATH);
const ARTIFACTS_DIR = path.join(BUILD_DIR, 'artifacts');
// const SOLIDITY_TEMPLATE = path.join(
//   require.resolve("snarkjs"),
//   "../../templates/verifier_groth16.sol.ejs"
// );
// const SOLIDITY_VERIFIER_PATH = path.join(
//   __dirname,
//   "../../contracts/src/Verifier.sol"
// );

function log(...message: any) {
  if (!SILENT) {
    console.log(...message);
  }
}

async function generateKeys(
  phase1Path: string,
  r1cPath: string,
  zKeyPath: string,
  vKeyPath: string,
  solidityVerifierPath: string
) {
  await snarkjs.zKey.newZKey(r1cPath, phase1Path, zKeyPath + ".step1", console);
  log("✓ Partial ZKey generated");

  await snarkjs.zKey.contribute(
    zKeyPath + ".step1",
    zKeyPath + ".step2",
    "Contributer 1",
    ZKEY_ENTROPY,
    console
  );
  log("✓ First contribution completed");

  await snarkjs.zKey.beacon(
    zKeyPath + ".step2",
    zKeyPath,
    "Final Beacon",
    ZKEY_BEACON,
    10,
    console
  );
  log("✓ Beacon applied");

  // Verification key
  const vKey = await snarkjs.zKey.exportVerificationKey(zKeyPath, console);
  fs.writeFileSync(vKeyPath, JSON.stringify(vKey, null, 2));
  log(`✓ Verification key exported - ${vKeyPath}`);

  // // Solidity verifier
  // const templates = {
  //   groth16: fs.readFileSync(SOLIDITY_TEMPLATE, "utf8"),
  // };
  // const code = await snarkjs.zKey.exportSolidityVerifier(zKeyPath, templates, console);
  // fs.writeFileSync(solidityVerifierPath, code);
  // log(`✓ Solidity verifier exported - ${solidityVerifierPath}`);

  // Cleanup
  ["", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"].forEach((suffix) => {
    if (fs.existsSync(zKeyPath + ".step1" + suffix))
      fs.unlinkSync(zKeyPath + ".step1" + suffix);
    if (fs.existsSync(zKeyPath + ".step2" + suffix))
      fs.unlinkSync(zKeyPath + ".step2" + suffix);
  });
}

async function exec() {

  const circuitPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}.r1cs`);
  if (!fs.existsSync(circuitPath)) {
    throw new Error(`${circuitPath} does not exist.`);
  }

  // Create artifacts directory and copy build files
  fs.mkdirSync(path.join(BUILD_DIR, 'artifacts'), { recursive: true });

  fs.copyFileSync(
    path.join(BUILD_DIR, `${CIRCUIT_NAME}.r1cs`),
    path.join(ARTIFACTS_DIR, `${CIRCUIT_NAME}.r1cs`)
  );
  fs.copyFileSync(
    path.join(BUILD_DIR, `${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm`),
    path.join(ARTIFACTS_DIR, `${CIRCUIT_NAME}.wasm`)
  );
  
  const zKeyPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}.zkey`);

  await generateKeys(
    PHASE1_PATH,
    circuitPath,
    zKeyPath,
    path.join(ARTIFACTS_DIR, `${CIRCUIT_NAME}.vkey.json`),
    // SOLIDITY_VERIFIER_PATH
    ""
  );
  log("✓ zkey, vkey and Solidity verifier generated");

  // Compress zkeys and copy to artifacts directory
  ["", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"].forEach((suffix) => {
    fs.writeFileSync(
      path.join(ARTIFACTS_DIR, `${CIRCUIT_NAME}.zkey`) + suffix + '.gz',
      pako.gzip(fs.readFileSync(zKeyPath + suffix))
    );
  });

  log(`✓ All artifacts saved to ${ARTIFACTS_DIR} directory`);
}

exec()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.log("Error: ", err);
    process.exit(1);
  });
