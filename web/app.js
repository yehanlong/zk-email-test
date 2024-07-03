// 导入模块
const express = require("express");
// 解析json请求体
const bodyParser = require("body-parser");

const router = require("./router.js");

// 创建一个express服务
const app = express();

// 解析 application/text 格式的请求体
app.use(bodyParser.text());
// express.urlencoded，便捷访问请求表单数据
app.use(express.urlencoded({ extended: false }));

// 为服务添加路由
app.use(router);

console.log("开始启动服务。。。");
// 启动服务，指定端口为 3000
app.listen(3000, (err) => {
  if (err) {
    console.error("Failed to start server:", err);
  } else {
    console.log("Server is running on port 3000");
  }
});
