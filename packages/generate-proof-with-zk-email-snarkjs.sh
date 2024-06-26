#!/bin/bash

# # ./generate-proof-with-zk-email-snarkjs.sh
# # ./generate-proof-with-zk-email-snarkjs.sh pick-one demo-zk-email-one build-one-test proofs-one-test 10 parallel 3
# # ./generate-proof-with-zk-email-snarkjs.sh pick-two demo-zk-email-two build-two-test proofs-two-test 1 serial
# # ./generate-proof-with-zk-email-snarkjs.sh pick-two demo-zk-email-two build-two-test proofs-two-test 10 parallel 3
# # ./generate-proof-with-zk-email-snarkjs.sh pick-three demo-zk-email-three build-three-test proofs-three-test 1 serial
# # ./generate-proof-with-zk-email-snarkjs.sh pick-three demo-zk-email-three build-three-test proofs-three-test 10 parallel 3

WORKING_DIR=${1:-pick-one}
CIRCOM_FILE_NAME=${2:-demo-zk-email-one}
BUILD_DIR=${3:-build-one-test}
OUTPUT_DIR_BASE=${4:-proofs-one-test}
NUM_ITERATIONS=${5:-1}
MODE=${6:-serial}
MAX_PARALLEL=${7:-3}

echo "WORKING_DIR: $WORKING_DIR"

cd "$WORKING_DIR/helps" || { echo "目录切换失败"; exit 1; }

execute_command() {
    local index=$1
    echo "Executing task $index"
    local output_dir="${OUTPUT_DIR_BASE}_${index}"

    mkdir -p ../"$output_dir"

    start_time=$(node -e 'console.log(new Date().getTime())')

    npx ts-node $CIRCOM_FILE_NAME-test.ts --email-file ../../eml/zkemail-demo-test.eml --circuit-name $CIRCOM_FILE_NAME --build-dir ../$BUILD_DIR --output-dir ../$output_dir --silent

    end_time=$(node -e 'console.log(new Date().getTime())')
    elapsed=$((end_time - start_time))
    echo "Execution task $index time: $elapsed ms"
} 

parallel_execution() {
    local i=1
    local running_jobs=0
    local pids=()

    while [ $i -le $NUM_ITERATIONS ] || [ ${#pids[@]} -gt 0 ]; do
        if [ $running_jobs -lt $MAX_PARALLEL ] && [ $i -le $NUM_ITERATIONS ]; then
            execute_command $i &
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
}

serial_execution() {
    for (( i=1; i<=$NUM_ITERATIONS; i++ ))
    do
        execute_command $i
    done
}

if [ "$MODE" == "parallel" ]; then
    parallel_execution
elif [ "$MODE" == "serial" ]; then
    serial_execution
else
    echo "Invalid mode. Use 'parallel' or 'serial'."
    exit 1
fi