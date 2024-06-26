#!/bin/bash

# # ./generate-proof-with-rapidsnark.sh
# # ./generate-proof-with-rapidsnark.sh pick-one demo-zk-email-one build-one proofs-one 10 parallel 3
# # ./generate-proof-with-rapidsnark.sh pick-two demo-zk-email-two build-two proofs-two 1 serial
# # ./generate-proof-with-rapidsnark.sh pick-two demo-zk-email-two build-two proofs-two 10 parallel 3
# # ./generate-proof-with-rapidsnark.sh pick-three demo-zk-email-three build-three proofs-three 1 serial
# # ./generate-proof-with-rapidsnark.sh pick-three demo-zk-email-three build-three proofs-three 10 parallel 3

WORKING_DIR=${1:-pick-one}
CIRCOM_FILE_NAME=${2:-demo-zk-email-one}
BUILD_DIR=${3:-build-one}
OUTPUT_DIR_BASE=${4:-proofs-one}
NUM_ITERATIONS=${5:-1}
MODE=${6:-serial}
MAX_PARALLEL=${7:-3}

BIN_DIR=../rapidsnark_test/rapidsnark/package/bin

TARGET_DIR=$BIN_DIR/$CIRCOM_FILE_NAME

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

npx ts-node scripts/input-generate.ts --email-file eml/zkemail-demo-test.eml --output-dir $TARGET_DIR --working-dir $WORKING_DIR
echo "Input files generated"

SOURCE_JS_DIR="$WORKING_DIR/$BUILD_DIR/${CIRCOM_FILE_NAME}_js/"
SOURCE_ZKEY_FILE="$WORKING_DIR/$BUILD_DIR/$CIRCOM_FILE_NAME-final.zkey"
SOURCE_VKEY_FILE="$WORKING_DIR/$BUILD_DIR/$CIRCOM_FILE_NAME.vkey.json"

copy_if_not_exists() {
    local source_file=$1
    local target_dir=$2

    if [ ! -f "$target_dir/$(basename $source_file)" ]; then
        cp -r "$source_file" "$target_dir"
    else
        echo "File $(basename $source_file) already exists in $target_dir. Skipping copy."
    fi
}

copy_if_not_exists "$SOURCE_JS_DIR" "$TARGET_DIR"
copy_if_not_exists "$SOURCE_ZKEY_FILE" "$TARGET_DIR"
copy_if_not_exists "$SOURCE_VKEY_FILE" "$TARGET_DIR"

cd $BIN_DIR || { echo "目录切换失败"; exit 1; }

execute_command() {
    local index=$1
    echo "Executing task $index"
    local output_dir="$CIRCOM_FILE_NAME/${OUTPUT_DIR_BASE}-${index}"

    mkdir -p "$output_dir"

    start_time=$(node -e 'console.log(new Date().getTime())')

    node $CIRCOM_FILE_NAME/generate_witness.js $CIRCOM_FILE_NAME/$CIRCOM_FILE_NAME.wasm $CIRCOM_FILE_NAME/input.json $output_dir/witness.wtns
    wait
    
    ./prover $CIRCOM_FILE_NAME/$CIRCOM_FILE_NAME-final.zkey $output_dir/witness.wtns $output_dir/proof.json $output_dir/public.json

    end_time=$(node -e 'console.log(new Date().getTime())')
    elapsed=$((end_time - start_time))
    echo "Execution task $index time: $elapsed ms"
    echo $elapsed
} 

parallel_execution() {
    local i=1
    local running_jobs=0
    local pids=()
    local times=()

    while [ $i -le $NUM_ITERATIONS ] || [ ${#pids[@]} -gt 0 ]; do
        if [ $running_jobs -lt $MAX_PARALLEL ] && [ $i -le $NUM_ITERATIONS ]; then
            times[i]=$(execute_command $i &)
            pids+=($!)
            ((i++))
            ((running_jobs++))
        else
            for pid in "${pids[@]}"; do
                if ! kill -0 $pid 2>/dev/null; then
                    wait $pid
                    pids=(${pids[@]/$pid})
                    ((running_jobs--))
                fi
            done
            sleep 1  # Add a short delay to prevent busy waiting
        fi
    done

    wait

    # echo "Execution times: ${times[@]}"
    calculate_statistics "${times[@]}"
}

serial_execution() {
    local times=()

    for (( i=1; i<=$NUM_ITERATIONS; i++ ))
    do
        times[i]=$(execute_command $i)
    done

    echo "Execution times: ${times[@]}"
    calculate_statistics "${times[@]}"
}

calculate_statistics() {
    local times=("$@")
    local total_time=0
    local max_time=0
    local min_time=999999999
    local count=${#times[@]}

    for time in "${times[@]}"; do
        total_time=$((total_time + time))
        if (( time > max_time )); then max_time=$time; fi
        if (( time < min_time )); then min_time=$time; fi
    done

    local avg_time=$((total_time / count))

    echo "Total time: $total_time ms"
    echo "Average time: $avg_time ms"
    echo "Max time: $max_time ms"
    echo "Min time: $min_time ms"
}

if [ "$MODE" == "parallel" ]; then
    parallel_execution
elif [ "$MODE" == "serial" ]; then
    serial_execution
else
    echo "Invalid mode. Use 'parallel' or 'serial'."
    exit 1
fi
exit 0
