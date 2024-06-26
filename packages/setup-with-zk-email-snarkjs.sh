#!/bin/bash

# # ./setup-with-zk-email-snarkjs.sh
# # ./setup-with-zk-email-snarkjs.sh pick-two demo-zk-email-two build-two-test
# # ./setup-with-zk-email-snarkjs.sh pick-three demo-zk-email-three build-three-test

WORKING_DIR=${1:-pick-one}
CIRCOM_FILE_NAME=${2:-demo-zk-email-one}
BUILD_DIR=${3:-build-one-test}
# OUTPUT_DIR=${1:-proofs-two-test}

cd $WORKING_DIR || { echo "目录切换失败"; exit 1; }

if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p "$BUILD_DIR"
fi
# if [ ! -d "$OUTPUT_DIR" ]; then
#     mkdir -p "$OUTPUT_DIR"
# fi

if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME.r1cs" ]; then
    circom -l ../../node_modules circuits/$CIRCOM_FILE_NAME.circom --wasm --r1cs --sym -o $BUILD_DIR
    wait
else
    echo "已存在 $BUILD_DIR/$CIRCOM_FILE_NAME.r1cs，跳过编译。"
fi

PTAU_FINAL="../powersOfTau28_hez_final_22.ptau"

if [ ! -f "$PTAU_FINAL" ]; then
    cd .. || { echo "目录切换失败"; exit 1; }
    URL="https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_22.ptau"
    OUTPUT_FILE="powersOfTau28_hez_final_22.ptau"
    curl -o "$OUTPUT_FILE" "$URL"
    cd $WORKING_DIR || { echo "目录切换失败"; exit 1; }
else
    echo "Tau已设置，跳过生成。"
fi

if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME.zkey" ]; then
    cd $BUILD_DIR || { echo "目录切换失败"; exit 1; }
    NODE_OPTIONS=--max-old-space-size=10240 npx ts-node ../../scripts/dev-setup.ts  --working-dir $WORKING_DIR --circuit-name $CIRCOM_FILE_NAME --build-dir $BUILD_DIR
    wait
    cd .. || { echo "目录切换失败"; exit 1; }
else
    echo "跳过zkey生成。"
fi

# cd helps || { echo "目录切换失败"; exit 1; }
# echo "Running generate proof"
# npx ts-node generate-proof-two.ts --email-file ../../eml/zkemail-demo-test.eml --circuit-name $CIRCOM_FILE_NAME --build-dir ../$BUILD_DIR --output-dir ../$OUTPUT_DIR