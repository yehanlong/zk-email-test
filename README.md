# zk-email-test

## 使用步骤

1. install：
    ```bash
    yarn install
    ```

2. 进入 `packages` 目录：
    ```bash
    cd packages
    ```

3. 进行setup：
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

4. 使用官方snarkjs生成pick-one电路的proof：
    ```bash
    chmod +x generate-proof.sh
    ./generate-proof.sh
    ```

5. 安装rapidsnark：
    ```bash
    chmod +x rapidsnark-install.sh
    ./rapidsnark-install.sh
    ```

6. 使用rapidsnark生成pick-one电路的proof：
    ```bash
    chmod +x generate-proof-with-rapidsnark.sh
    ./generate-proof-with-rapidsnark.sh
    ```
7. 其他电路请参考脚本开头注释