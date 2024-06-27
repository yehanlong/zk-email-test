const program = require("commander");
const path = require('path');
const { generateInputs: generateInputsOne } = require("../pick-one/helps/generate-input-one");
const { generateInputs: generateInputsTwo } = require("../pick-two/helps/generate-input-two");
const { generateInputs: generateInputsThree } = require("../pick-three/helps/generate-input-three");

// program
//   .requiredOption("--email-file <string>", "Path to email file")
//   .requiredOption("--output-dir <string>", "output-dir")
//   .requiredOption("--working-dir <string>", "working-dir");

// program.parse();
// const params = program.opts();

interface InputGenerateParams {
  emailFile: string;
  outputDir: string;
  workingDir: string;
}

async function inputGenerate(params: InputGenerateParams) {
  
  const { emailFile, outputDir, workingDir } = params;

  switch (workingDir) {
    case 'pick-one':
      await generateInputsOne(emailFile,outputDir);
      break;
    case 'pick-two':
      await generateInputsTwo(emailFile,outputDir);
      break;
    case 'pick-three':
      await generateInputsThree(emailFile,outputDir);
      break;
    default:
      throw new Error(`Unknown working-dir: ${workingDir}`);
  }
}

// inputGenerate().catch((err) => {
//   console.error("Error generating input", err);
//   process.exit(1);
// });

export { inputGenerate, InputGenerateParams };
