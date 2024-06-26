#!/bin/bash

# # ./setup.sh
# # ./setup.sh pick-two demo-zk-email-two build-two 

WORKING_DIR=${1:-pick-one}
CIRCOM_FILE_NAME=${2:-demo-zk-email-one}
BUILD_DIR=${3:-build-one}
# OUTPUT_DIR=${4:-proofs-one}

cd $WORKING_DIR || { echo "目录切换失败"; exit 1; }

# 确保目标目录存在
if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p "$BUILD_DIR"
fi
# if [ ! -d "$OUTPUT_DIR" ]; then
#     mkdir -p "$OUTPUT_DIR"
# fi

# 编译
if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME.r1cs" ]; then
    # 编译
    circom -l ../../node_modules circuits/$CIRCOM_FILE_NAME.circom --wasm --r1cs --sym -o $BUILD_DIR
    wait
else
    echo "已存在 $BUILD_DIR/$CIRCOM_FILE_NAME.r1cs，跳过编译。"
fi

# 设置Tau
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

if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME-final.zkey" ]; then
    cd $BUILD_DIR || { echo "目录切换失败"; exit 1; }
    # Phase 2
    echo "Phase 2 start"
    NODE_OPTIONS=--max-old-space-size=10240 snarkjs groth16 setup $CIRCOM_FILE_NAME.r1cs ../../powersOfTau28_hez_final_22.ptau $CIRCOM_FILE_NAME-0000.zkey
    wait
    echo "5678" | NODE_OPTIONS=--max-old-space-size=10240 snarkjs zkey contribute $CIRCOM_FILE_NAME-0000.zkey $CIRCOM_FILE_NAME-final.zkey --name="1st Contributor Name" -v
    wait
    snarkjs zkey export verificationkey $CIRCOM_FILE_NAME-final.zkey $CIRCOM_FILE_NAME.vkey.json
    wait
    echo "Phase 2 end"
    cd .. || { echo "目录返回失败"; exit 1; }
else
    echo "跳过zkey生成。"
fi

# cd helps || { echo "目录切换失败"; exit 1; }
# echo "Running generate proof"
# npx ts-node generate-full-prove-two.ts --email-file ../../eml/zkemail-demo-test.eml --circuit-name $CIRCOM_FILE_NAME --build-dir ../$BUILD_DIR --output-dir ../$OUTPUT_DIR

echo "end"