// 导入模块
const express = require("express");
const { exec } = require("child_process");
const fs = require("fs");
const crypto = require("crypto");
const util = require("util");
const multer = require("multer");

const router = express.Router();
// 指定上传文件的目标文件夹
const upload = multer({ dest: "packages/eml/" });

router.get("/hello-world", function (req, res) {
  console.log("/hello-world 请求来了");
  res.send("ok\n");
});
router.post("/upload", upload.single("file"), (req, res) => {
  const file = req.file; // 获取上传的文件信息
  console.log(file);
  const fileContent = fs.readFileSync(file.path);
  console.log(`fileContent = ${fileContent}`);
  res.send("文件上传成功");
});
router.post("/gen-proof-snarkjs", upload.single("file"), function (req, res) {
  // req.params 可以获取路径中的参数
  const { bodyHash, isOver } = handleFile(req, res, "packages/pick-one");
  if (isOver) return;

  // 调用 shell 命令
  // const execPromise = util.promisify(exec);
  const command = `cd packages && mkdir -p pick-one/${bodyHash}_1 && ./generate-proof-with-zk-email-snarkjs.sh pick-one demo-zk-email-one build-one-test ${bodyHash} 1 serial 1 ../../eml/${bodyHash}.eml`;
  console.log(`要执行的命令：${command}`);
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`执行命令时发生错误: ${error.message}`);
      res.send(`执行脚本失败，请联系开发人员：${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`命令执行结果包含错误信息: ${stderr}`);
      res.send(`执行脚本失败，请联系开发人员：${stderr}`);
      return;
    }
    console.log(`命令执行结果: ${stdout}`);
    handle(req, res, "./packages/pick-one/" + bodyHash);
  });
});

router.post(
  "/gen-proof-rapidsnark",
  upload.single("file"),
  function (req, res) {
    // req.params 可以获取路径中的参数
    const { bodyHash, isOver } = handleFile(
      req,
      res,
      "rapidsnark_test/rapidsnark/package/bin/demo-zk-email-one",
    );
    if (isOver) return;

    // 调用 shell 命令
    // const execPromise = util.promisify(exec);
    const command = `cd packages && ./generate-proof-with-rapidsnark.sh pick-one demo-zk-email-one build-one ${bodyHash} 1 serial 1 eml/${bodyHash}.eml`;
    console.log(`要执行的命令：${command}`);
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`执行命令时发生错误: ${error.message}`);
        res.send(`执行脚本失败，请联系开发人员：${error.message}`);
        return;
      }
      if (stderr) {
        console.error(`命令执行结果包含错误信息: ${stderr}`);
        res.send(`执行脚本失败，请联系开发人员：${stderr}`);
        return;
      }
      console.log(`命令执行结果: ${stdout}`);
      handle(
        req,
        res,
        "rapidsnark_test/rapidsnark/package/bin/demo-zk-email-one/" + bodyHash,
      );
    });
  },
);

async function handle(req, res, resultPathPrefix) {
  console.log(`handle resultPathPrefix=${resultPathPrefix}`);
  // 读取结果返回
  const proofData = fs.readFileSync(
    resultPathPrefix + "_1/proof.json",
    "UTF-8",
  );
  const publicData = fs.readFileSync(
    resultPathPrefix + "_1/public.json",
    "UTF-8",
  );
  let r = { proof: JSON.parse(proofData), public: JSON.parse(publicData) };
  console.log("返回结果：", r);
  res.send(r);
}

function handleFile(req, res, basePath) {
  // req.params 可以获取路径中的参数
  const file = req.file; // 获取上传的文件信息
  console.log(file);

  const data = fs.readFileSync(file.path);
  console.log(`data = ${data}`);

  const bodyHash = crypto.createHash("sha256").update(data).digest("hex");
  const proofPath = `${basePath}/${bodyHash}_1/proof.json`;

  const emlPath = `packages/eml/${bodyHash}.eml`;
  if (!fs.existsSync(emlPath)) {
    fs.writeFileSync(`packages/eml/${bodyHash}.eml`, data);
    console.log(`写入文件 ${bodyHash}.eml, content=${data}`);
  } else {
    console.log(`文件已存在 ${bodyHash}.eml`);
  }
  fs.unlink(file.path, (err) => {
    if (err) {
      console.error(err);
      return { bodyHash: bodyHash, isOver: false };
    }
    console.log("临时文件删除成功 " + file.path);
  });

  if (fs.existsSync(proofPath)) {
    handle(req, res, `${basePath}/${bodyHash}`);
    return { bodyHash: bodyHash, isOver: true };
  }

  return { bodyHash: bodyHash, isOver: false };
}

module.exports = router;
