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

4. 使用官方snarkjs生成pick-one电路的proof：
    ```bash
    ./generate-proof.sh
    ```

5. 安装rapidsnark：
    ```bash
    ./rapidsnark-install.sh
    ```

6. 使用rapidsnark生成pick-one电路的proof：
    ```bash
    ./generate-proof-with-rapidsnark.sh
    ```
7. 其他电路请参考脚本开头注释