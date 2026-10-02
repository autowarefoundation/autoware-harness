---
description: |
  Use this skill when a `colcon build` has failed and the cause needs to be identified and fixed (for example "colcon build failed", "fix the build error", "package X does not build").
  Provides the steps to find the error in the build logs or in the summary from the `/awh-build-colcon` skill, classify it, and apply known fixes.
  Pass the failed package names or the error log path as the argument. If none is given, inspect `log/latest`.
name: awh-build-fix-colcon
allowed-tools: Glob Grep Read Edit Bash
---

# Fixing a failed colcon build

For the build commands and options, see the `/awh-build-colcon` skill.

## Table of contents

- [Triage](#triage)
- [Symptoms](#symptoms)
- [Repeating fix and build](#repeating-fix-and-build)

## Triage

1. Identify the failed packages and their causes in `<workspace>/log/latest/` or in the `/awh-build-colcon` summary.
2. Find the **first** error. Later errors are often consequences of it.

## Symptoms

### CMake

A package `<pkg>` fails in the `cmake` step. The `cmake` step fails with this output:

```text
Could not find a package configuration file provided by "Foo" with any of
the following names:

FooConfig.cmake
foo-config.cmake
```

This error often occurs after `git pull` or `vcs pull` updates `CMakeLists.txt` or `package.xml`.

- In a host environment, run `rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO` at the workspace root to install the missing `libfoo-dev` or `ros-<distro>-foo-dev` packages.
- In a Docker or devcontainer environment, ask the user to stop the container and update the base image.

Otherwise, Autoware or vendor libraries may have been updated or added.

- Run `git pull` to update `<workspace>/autoware.repos`, then compare each entry's version with the local checkout. If `autoware.repos` changed, run `vcs import src < autoware.repos`.
- Then run `vcs pull src/` to update the dependencies. If the output lists **new packages**, they likely resolve the issue.

If you applied any of these fixes, run `rm -rf build/<pkg>` to remove the stale `CMakeCache.txt`.

### `g++` or `clang++` crashes from out-of-memory (OOM) errors

Autoware builds need a lot of memory, so the OOM killer can terminate the compiler. In that case, lower `--parallel-workers` to reduce memory use.

[Increasing the swap size](https://docs.autoware.org/main/community/support/troubleshooting/#insufficient-memory) also reduces OOM kills.

### Boost.Geometry compilation error

A package that combines Lanelet2 with Boost.Geometry operations can produce very long compilation errors. Common causes:

- `<lanelet2_core/geometry/<object>.hpp>` is not included before `boost::geometry::algorithm(ObjectType)` is called. This header file provides Boost.Geometry adapter definition.
- The Lanelet2 object is not converted to a 2D type. Use `.polygon2d()` or `lanelet::utils::to2D(object)`.

See the [Boost.Geometry error guide](https://github.com/fzi-forschungszentrum-informatik/Lanelet2/blob/master/lanelet2_core/doc/GeometryPrimer.md#understanding-boost-geometrys-errors).

## Repeating fix and build

Apply the fix and rebuild until all target packages succeed. Report progress after each cycle.
