.PHONY: all clean benchmark-all benchmark-earthly benchmark-bake benchmark-dagger

# Number of times to run each benchmark. Can be overridden from the command line (e.g., make benchmark-all RUNS=5)
RUNS ?= 3

# --- Main Targets ---

all: benchmark-all

# A target to run all benchmarks sequentially.
benchmark-all: benchmark-earthly benchmark-bake benchmark-dagger

# A target to clean up all generated files from all tools.
clean:
	@echo "Cleaning up generated files..."
	@rm -f results.csv
	@rm -rf ros-apt-source/dagger/output
	@rm -rf ros-apt-source/docker-bake/output
	@rm -rf ros-apt-source/output

# --- Individual Benchmark Targets ---

benchmark-earthly:
	@./run_benchmark.sh earthly $(RUNS)

benchmark-bake:
	@./run_benchmark.sh docker-bake $(RUNS)

benchmark-dagger:
	@./run_benchmark.sh dagger $(RUNS)
