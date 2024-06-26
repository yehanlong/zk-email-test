# zk-email-test

## 安装步骤

1. 安装依赖：
    ```bash
    yarn install
    ```

2. 进入 `packages` 目录：
    ```bash
    cd packages
    ```

3. 进行setup.sh：
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