import { program } from "commander";
import { inputGenerate, InputGenerateParams } from './scripts/input-generate';
import path from "path";
import fs from "fs";
import async from "async";
const snarkjs = require("snarkjs");

//npx ts-node generate-proof-parallel.ts
//npx ts-node generate-proof-parallel.ts --working-dir pick-one --thread-num 2 --iteration-num 2
//npx ts-node generate-proof-parallel.ts --working-dir pick-two --thread-num 2 --iteration-num 2
//npx ts-node generate-proof-parallel.ts --working-dir pick-three --thread-num 2 --iteration-num 2

program
  .option("--working-dir <string>", "working-dir")
  .option("--circuit-name <string>", "circuit-name")
  .option("--build-dir <string>", "build-dir")
  .option("--output-dir <string>", "output-dir")
  .option("--thread-num <number>", "thread-num")
  .option("--iteration-num <number>", "iteration-num");

program.parse();
const args = program.opts();

const WORKING_DIR: string = args.workingDir || "pick-one";
const CIRCUIT_NAME: string = args.circuitName || "demo-zk-email-one";
const SCRIPT_DIR: string = path.join(WORKING_DIR, "/helps");
const BUILD_DIR: string = args.buildDir || path.join(WORKING_DIR, "/build-one");
const OUTPUT_DIR: string = args.outputDir || path.join(WORKING_DIR, "/proofs-one-parallel");
const THREAD_NUM: number = args.threadNum || 1;
const ITERATION_NUM: number = args.iterationNum || 1;

console.log(`Using configuration:
WORKING_DIR=${WORKING_DIR}
CIRCUIT_NAME=${CIRCUIT_NAME}
BUILD_DIR=${BUILD_DIR}
OUTPUT_DIR=${OUTPUT_DIR}
THREAD_NUM=${THREAD_NUM}
ITERATION_NUM=${ITERATION_NUM}`);

const generateScriptPath: string = path.join(SCRIPT_DIR, CIRCUIT_NAME + ".ts");
const allRecords: number[] = [];
let totalStartTime: number;

async function generateProof(numberOfIterations: number, threadIndex: number): Promise<void> {
    if (!totalStartTime) {
        totalStartTime = Date.now();
    }
    const wasmPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm`);
    const zkeyPath = path.join(BUILD_DIR, `${CIRCUIT_NAME}-final.zkey`);
    console.log(`generateProof start numberOfIterations=${numberOfIterations}, threadIndex=${threadIndex}`);
    const records: number[] = [];

    for (let i = 0; i < numberOfIterations; i++) {
        const startTime = Date.now();
        const outputDir = `${OUTPUT_DIR}-${threadIndex}-${i}`;
        const params: InputGenerateParams = {
            emailFile: 'eml/zkemail-demo-test.eml',
            outputDir: outputDir,
            workingDir: WORKING_DIR,
        };
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        try {
            await inputGenerate(params);
            const input = JSON.parse(fs.readFileSync(path.join(outputDir, "input.json"), 'utf-8'));
            const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, wasmPath, zkeyPath);

            const endTime = Date.now();
            const executionTime = endTime - startTime;
            console.log(`Proof generation time for ${threadIndex}: ${executionTime} ms`);

            records.push(executionTime);
            allRecords.push(executionTime);
        } catch (error) {
            console.error(`Error generating proof for ${threadIndex}:`, error);
        }
    }

    console.log(`thread ${threadIndex} result for ${records.length} times: min=${Math.min(...records)}, avg=${avg(records)}, max=${Math.max(...records)}`);

    if (allRecords.length === numberOfIterations * THREAD_NUM) {
        const realCost = Date.now() - totalStartTime;
        console.log("----------------");
        console.log(`final result for ${allRecords.length} times: min=${Math.min(...allRecords)}, avg=${avg(allRecords)}, max=${Math.max(...allRecords)}, realCost=${realCost}, realAvg=${Math.ceil(realCost / allRecords.length)}`);
        console.log("----------------");
        process.exit(0);
    }
}

function avg(arr: number[]): number {
    if (!arr || arr.length <= 0) return -1;
    const sum = arr.reduce((acc, val) => acc + val, 0);
    return Math.ceil(sum / arr.length);
}

const threads: ((callback: (err?: any) => void) => void)[] = [];
for (let i = 0; i < THREAD_NUM; i++) {
    threads.push(async (callback) => {
        console.log(`thread ${i} starts`);
        await generateProof(ITERATION_NUM, i);
        if (callback) callback();
    });
}

async.parallel(threads, (err: any, results: any) => {
    if (err) {
        console.error("Error in parallel execution:", err);
    } else {
        console.log(results);
    }
});
