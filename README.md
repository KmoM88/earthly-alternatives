# Earthly Alternatives Comparison

## Objective

The `earthly` project has transitioned to a state of limited maintenance. This poses a potential risk regarding security vulnerabilities and the lack of future support or new features.

The objective of this project is to analyze and compare viable alternatives to Earthly for our build processes. The main options being considered are:
* Dagger (using the Python SDK)
* Docker Bake

This repository will serve as a testbed to evaluate these alternatives. We will import several of our existing microservices as Git submodules and implement their build logic using each of the candidate tools. The goal is to produce a comprehensive comparative analysis to inform our migration strategy.

---

## Earthly in OSRF

Earthly is currently used in several OSRF repositories, including:

- ros-infrastructure/ros-apt-source
- ros-infrastructure/infrastructure-website
- ros-infrastructure/infra-variants
- openrobotics/gz_oci_images

---

## Testing ground and migration scope

To provide an accurate benchmark, the evaluation was conducted against a representative subset of our actual infrastructure.

- Test Repository: ros-infrastructure/ros-apt-source
- Target workflow for Testing: build-test-debs.yaml
    - Job: build-ros2-apt-source

---

##  Qualitative Comparison: Dagger vs. Docker Bake

This section evaluates the architectural approach and developer experience of both tools.

| Feature / Tool | Dagger (Python SDK) | Docker Bake |
|----------------|---------------------|-------------|
| Paradigm | Declarative Configuration as Software (CaaS). Full programmatic control via Python. | Declarative Configuration (HCL). Extension of standard Docker tools. |
| Execution | Asynchronous DAG evaluation; engine manages its own containers. | Native BuildKit frontend orchestration. |
| Flexibility | Extremely high. Allows complex logic, API integrations, and direct module imports. | Moderate. Excellent for static matrices, but lacks advanced control flow. |
| Learning Curve | Steep. Requires understanding of async execution, lazy evaluation, and caching caveats. | Low. Highly familiar to anyone with Docker/Dockerfile experience. |
| Debugging | Powerful programmatic breakpoints (.terminal()). | Relies on BuildKit debug modes or standard log inspection. |

---

## Quantitative Comparison: Benchmark Analysis
Note: Benchmarks were run on identical GitHub Actions runners (ubuntu-latest) and only running the build jobs for all distributions in parallel.

| Metric | Earthly (Baseline) | Dagger (Python SDK) | Docker Bake |
|--------|--------------------|---------------------|-------------|
| Engine Setup Time | ~2 s | ~10 s | (Native to runner) |
| Cold Build (All Distros) | ~115 s | ~145 s | ~ 114 s |
| Cached Build (All Distros) | ~1.7 s | ~ 4.2 s | < 1 s |
| Code Footprint (Lines) | 106 | 227 | 162 |

For the job migrated `build-ros2-apt-source` in GHA where the build and test is done by distribution on a single runner each, the times are arround 1 min for any of the tools. More deep analysis can be done on setting up caches for each tool.

---

## Conclusion (subjective)

While Dagger presents a significantly more complete, powerful, and versatile ecosystem for infrastructure management, it introduces an abstraction layer and an asynchronous complexity that seems to exceeds the needs for which Earthly is used.

For the specific use cases of the OSRF CI workflows Docker Bake is the more pragmatic choice. It provides a more direct, faster-to-implement solution with a negligible learning curve, effectively replacing Earthly's parallelization capabilities without over-engineering the pipeline.

---

### Anex: Issue in ros-apt-sources

During the migration of the job `build-ros2-apt-source` an issue was found in the original Earthly file. Resported in [link].