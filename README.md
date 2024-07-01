# zk-email-test

## 使用步骤
0. 根据自己本机环境选择是否需要提供的脚本进行各种依赖的安装（node、yarn、git、rust、circom、snarkjs）
1. install：
    ```bash
    yarn install
    ```

2. 进入 `packages` 目录：
    ```bash
    cd packages
    chmod +x *.sh
    ```

3. 进行setup：
    ```bash
    ./setup.sh
    ./setup.sh pick-two demo-zk-email-two build-two
    ./setup.sh pick-three demo-zk-email-three build-three
    ```

4. 使用官方snarkjs生成proof(单进程、多进程)：
    ```bash
    ./generate-proof.sh
    ./generate-proof.sh pick-one demo-zk-email-one build-one proofs-one 10 parallel 3
    ./generate-proof.sh pick-two demo-zk-email-two build-two proofs-two 1 serial
    ./generate-proof.sh pick-two demo-zk-email-two build-two proofs-two 10 parallel 3
    ./generate-proof.sh pick-three demo-zk-email-three build-three proofs-three 1 serial
    ./generate-proof.sh pick-three demo-zk-email-three build-three proofs-three 10 parallel 3
    ```

5. 安装rapidsnark：
    ```bash
    ./rapidsnark-install.sh
    ```

6. 使用rapidsnark生成pick-one电路的proof：
    ```bash
    ./generate-proof-with-rapidsnark.sh
    ```
7. 使用官方snarkjs生成proof(多线程)：
    ```bash
    npx ts-node generate-proof-parallel.ts
    npx ts-node generate-proof-parallel.ts --working-dir pick-one --thread-num 2 --iteration-num 2
    npx ts-node generate-proof-parallel.ts --working-dir pick-two --circuit-name demo-zk-email-two   --build-dir build-two --output-dir proofs-two-parallel --thread-num 2 --iteration-num 2
    npx ts-node generate-proof-parallel.ts --working-dir pick-three --circuit-name demo-zk-email-three --build-dir build-three --output-dir proofs-three-parallel --thread-num 2 --iteration-num 2
    ```
8. 其他电路请参考脚本开头注释


## 问题
#### yarn 报错
```
yarn install v1.22.22
info No lockfile found.
[1/4] Resolving packages...
error Error: certificate has expired
    at TLSSocket.onConnectSecure (node:_tls_wrap:1674:34)
    at TLSSocket.emit (node:events:519:28)
    at TLSSocket._finishInit (node:_tls_wrap:1085:8)
    at ssl.onhandshakedone (node:_tls_wrap:871:12)
```
禁用SSL检查即可，因为是临时测试demo，无需严格SSL
`yarn config set strict-ssl false`
