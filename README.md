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
    npx ts-node generate-proof-parallel.ts --working-dir pick-two --thread-num 2 --iteration-num 2
    npx ts-node generate-proof-parallel.ts --working-dir pick-three --thread-num 2 --iteration-num 2
    ```
8. 其他电路请参考脚本开头注释