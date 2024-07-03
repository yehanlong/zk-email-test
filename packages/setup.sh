#!/bin/bash

# # ./setup.sh
# # ./setup.sh pick-two demo-zk-email-two build-two
# # ./setup.sh pick-three demo-zk-email-three build-three

WORKING_DIR=${1:-pick-one}
CIRCOM_FILE_NAME=${2:-demo-zk-email-one}
BUILD_DIR=${3:-build-one}
# OUTPUT_DIR=${4:-proofs-one}

cd $WORKING_DIR || { echo "目录切换失败"; exit 1; }

echo "进入当前目录：$(pwd)"

# 确保目标目录存在
if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p "$BUILD_DIR"
    echo "创建了目标文件夹：$BUILD_DIR"
fi
# if [ ! -d "$OUTPUT_DIR" ]; then
#     mkdir -p "$OUTPUT_DIR"
# fi

# 编译
if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME.r1cs" ]; then
    echo "开始编译 circom，当前目录 $(pwd)"
    # 编译
    circom -l ../../node_modules circuits/$CIRCOM_FILE_NAME.circom --wasm --r1cs --sym -o $BUILD_DIR
    if $? ;then
        echo "circom 编译完成，当前目录: $BUILD_DIR"
    else
        echo "circom 编译失败"
    fi
    wait
else
    echo "已存在 $BUILD_DIR/$CIRCOM_FILE_NAME.r1cs，跳过编译。"
fi

# 设置Tau
PTAU_FINAL="../powersOfTau28_hez_final_22.ptau"

if [ ! -f "$PTAU_FINAL" ]; then
    cd .. || { echo "目录切换失败"; exit 1; }
    echo "开始下载 ptau，当前目录：$(pwd)"
    URL="https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_22.ptau"
    OUTPUT_FILE="powersOfTau28_hez_final_22.ptau"
    curl -o "$OUTPUT_FILE" "$URL"
    cd $WORKING_DIR || { echo "目录切换失败"; exit 1; }
    echo "下载 ptau 完成，返回到当前目录：$(pwd)"
else
    echo "Tau已设置，跳过生成。"
fi

if [ ! -f "$BUILD_DIR/$CIRCOM_FILE_NAME-final.zkey" ]; then
    cd $BUILD_DIR || { echo "目录切换失败"; exit 1; }
    # Phase 2
    echo "Phase 2 start 开始生成 init zkey 文件，当前目录：$(pwd)"
    NODE_OPTIONS=--max-old-space-size=10240 snarkjs groth16 setup $CIRCOM_FILE_NAME.r1cs ../../powersOfTau28_hez_final_22.ptau $CIRCOM_FILE_NAME-0000.zkey
    wait
    echo "Phase 2 生成 final zkey 文件，当前目录：$(pwd)"
    echo "5678" | NODE_OPTIONS=--max-old-space-size=10240 snarkjs zkey contribute $CIRCOM_FILE_NAME-0000.zkey $CIRCOM_FILE_NAME-final.zkey --name="1st Contributor Name" -v
    wait
    echo "Phase 2 生成 vkey 文件，当前目录：$(pwd)"
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
