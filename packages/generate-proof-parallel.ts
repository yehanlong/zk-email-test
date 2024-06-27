import { program } from "commander";
import { spawn } from 'child_process';
import path from "path";

program
  .option("--working-dir <string>", "working-dir")
  .option("--circuit-name <string>", "circuit-name")
  .option("--build-dir <string>", "build-dir")
  .option("--output-dir <string>", "output-dir")
  .option("--thread-num <number>", "thread-num")
  .option("--iteration-num <number>", "iteration-num");

program.parse();
const args = program.opts();

var WORKING_DIR = args.workingDir || path.join(__dirname,"pick-one");
var CIRCUIT_NAME = args.circuitName || "demo-zk-email-one";

var SCRIPT_DIR = path.join(WORKING_DIR, "/helps");

var BUILD_DIR = args.buildDir || path.join(WORKING_DIR, "/build-one");
var OUTPUT_DIR = args.outputDir || path.join(WORKING_DIR, "/proofs-one-parallel");
var THREAD_NUM = args.threadNum || 3;
var ITERATION_NUM = args.iterationNum || 10;

console.log(`Using configuration:
WORKING_DIR=${WORKING_DIR}
CIRCUIT_NAME=${CIRCUIT_NAME}
BUILD_DIR=${BUILD_DIR}
OUTPUT_DIR=${OUTPUT_DIR}
THREAD_NUM=${THREAD_NUM}
ITERATION_NUM=${ITERATION_NUM}`);


let generateScriptPath: string = path.join(SCRIPT_DIR, CIRCUIT_NAME + ".ts");
const allRecords: number[] = [];
let totalStartTime: number;

async function generateProof(numberOfIterations: number, threadIndex: number) {
    if (!totalStartTime) {
        totalStartTime = Date.now();
    }
    console.log(`generateProof start numberOfIterations=${numberOfIterations}, threadIndex=${threadIndex}`);

    const records: number[] = [];
    const promises: Promise<void>[] = [];
    
    for (let i = 0; i < numberOfIterations; i++) {
        const startTime: number = Date.now();

        const promise = new Promise<void>((resolve, reject) => {
            const child = spawn('npx', ['ts-node',
                generateScriptPath,
                '--email-file', 'eml/zkemail-demo-test.eml',
                '--circuit-name', CIRCUIT_NAME,
                '--build-dir', BUILD_DIR,
                '--output-dir', `${OUTPUT_DIR}-${threadIndex}-${i}`,
                '--silent'
            ]);

            child.on('close', (code) => {
                if (code === 0) {
                    const endTime: number = Date.now();
                    const executionTime: number = endTime - startTime;
                    console.log(`Proof generation time for ${threadIndex}-${i}: ${executionTime} ms`);
                    records.push(executionTime);
                    allRecords.push(executionTime);
                    resolve();
                } else {
                    reject(new Error(`Proof generation failed for ${threadIndex}-${i}. Exit code: ${code}`));
                }
            });

            child.on('error', (err) => {
              console.error(`Error spawning child process for ${threadIndex}-${i}:`, err);
            });
          
            child.stderr.on('data', (data) => {
              console.error(`Error output from child process for ${threadIndex}-${i}:`, data.toString());
            });
        });

        promises.push(promise);
    }

    try {
        await Promise.all(promises);
        console.log(`thread ${threadIndex} result for ${records.length} times: min=${Math.min(...records)}, avg=${avg(records)}, max=${Math.max(...records)}`);
    } catch (error) {
        console.error(`Error generating proofs for thread ${threadIndex}:`, error);
    }

    if (allRecords.length === numberOfIterations * THREAD_NUM) {
        const realCost: number = Date.now() - totalStartTime;
        console.log("----------------");
        console.log(`final result for ${allRecords.length} times: min=${Math.min(...allRecords)}, avg=${avg(allRecords)}, max=${Math.max(...allRecords)}, realCost=${realCost}, realAvg=${Math.ceil(realCost / allRecords.length)}`);
        console.log("----------------");
        process.exit(0);
    }
}

function avg(arr: number[]): number {
    if (!arr || arr.length <= 0) return -1;
    let sum: number = 0;
    for (let i = 0; i < arr.length; i++) {
        sum += arr[i];
    }
    return Math.ceil(sum / arr.length);
}

async function runParallelTasks(numTasks: number) {
    const tasks: Promise<void>[] = [];
    for (let i = 0; i < numTasks; i++) {
        tasks.push(generateProof(ITERATION_NUM, i));
    }

    await Promise.all(tasks);
}

runParallelTasks(THREAD_NUM).catch((err) => {
    console.error("Error running tasks:", err);
    process.exit(1);
});
