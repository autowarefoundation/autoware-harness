---
description: |
  Use this skill when building an Autoware workspace with colcon (for example "build Autoware", "build only this package").
  Provides the default build command and guidance for choosing options (package selection, build type, parallelism).
  Pass the target packages as the argument. If none is given, build the whole workspace.
name: awh-build-colcon
allowed-tools: Glob Grep Read Bash
context: fork
---

# Building Autoware with colcon

## Table of contents

- [Preconditions](#preconditions)
- [Default command](#default-command)
- [Options](#options)
- [Build](#build)
- [Report](#report)

## Preconditions

Locate the workspace root: walk up from the current directory to the directory that contains `src/`, with `build/`, `install/`, and `log/` at the same level.

Confirm that the ROS 2 distribution and any overlay workspaces are sourced.

1. Check that `$ROS_DISTRO` is set and `AMENT_PREFIX_PATH` points to its installation. If either is missing, run `source /opt/ros/<ROS_DISTRO>/setup.bash`.
2. In the Autoware Docker environment, the overlay is normally `/opt/autoware/`. If it exists, run `source /opt/<overlay>/setup.bash`.

## Default command

The [Autoware installation page](https://docs.autoware.org/main/installation/autoware/source-installation/#how-to-update-a-workspace) uses the following command for tutorials.

```bash
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
```

For development, use `RelWithDebInfo`, which keeps the debug information that you need to debug C++ code and analyze crashes. Run the following command and replace `<extra options>` as needed.

```bash
colcon build <extra options> --symlink-install --continue-on-error --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

## Options

| Purpose                                 | Option                                 | When needed                                                                                                                                                                                                      |
| --------------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Build selected packages only            | `--packages-select <pkg>`              | One package changed, or the changed packages do not depend on each other.                                                                                                                                        |
| Build a package and its dependencies    | `--packages-up-to <pkg>`               | The changed packages depend on each other, especially when a header file changed. Do not use `--packages-select`.                                                                                                |
| Build packages that depend on a package | `--packages-above <pkg>`               | A common or library package changed.                                                                                                                                                                             |
| Limit parallel jobs                     | `--parallel-workers <N>`               | The system load is high.                                                                                                                                                                                         |
| Show compiler output                    | `--event-handlers console_direct+`     | The compiler or linker output lacks enough detail.                                                                                                                                                               |
| Other build types                       | `-DCMAKE_BUILD_TYPE=Release` / `Debug` | Use `Release` for production or performance measurement. Use `Debug` for rich information in `gdb`. Combine with `--packages-up-to` or `--packages-above` so that all affected packages use the same build type. |

## Build

At the workspace root, call `colcon build` along with the options.

## Report

If `colcon build` succeeds, report `success`. Otherwise, report:

- the package name
- a summary of the failure reason
  - Lanelet2 template errors can be very long. Find the source line in the compiler output, which should include the local path and position, and ignore the rest.
