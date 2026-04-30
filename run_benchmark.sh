#!/bin/bash

TOOL_NAME="$1"
RUNS="$2"
shift 2 # Shift arguments to get tool-specific commands

# CSV Header
HEADER="tool,timestamp,run_number,elapsed_time_s,user_cpu_s,system_cpu_s,max_memory_kb"

# Ensure results.csv exists and has a header
if [ ! -f results.csv ]; then
    echo "$HEADER" > results.csv
fi

for i in $(seq 1 "$RUNS"); do
    echo "Run $i/$RUNS for $TOOL_NAME..."
    OUTPUT_DIR=""
    COMMAND=""

    case "$TOOL_NAME" in
        "earthly")
            OUTPUT_DIR="ros-apt-source/output"
            COMMAND="earthly ./ros-apt-source+build-all"
            ;;
        "docker-bake")
            OUTPUT_DIR="ros-apt-source/docker-bake/output"
            COMMAND="docker buildx bake build-all -f ./ros-apt-source/docker-bake/docker-bake.hcl"
            ;;
        "dagger")
            OUTPUT_DIR="ros-apt-source/dagger/output"
            COMMAND="python3 -m ros-apt-source.dagger.main build"
            ;;
        *)
            echo "Unknown tool: $TOOL_NAME"
            exit 1
            ;;
    esac

    rm -rf "$OUTPUT_DIR"
    /usr/bin/time -a -o results.csv -f "$TOOL_NAME,`date +%s`,$i,%e,%U,%S,%M" $COMMAND
done
