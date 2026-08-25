---
description: |
Use this skill when one creates / reviews or lints .msg, .srv, .action files to align with Autoware's style guideline.
When prompted to lint given message files, report the result in the specified format.
name: awh-interface-msg-format
allowed-tools: Read, Grep, Glob, WebFetch
---

# Autoware Harness for message schema format

One should refer to [latest document](https://autowarefoundation.github.io/autoware-documentation/main/contributing/coding-guidelines/ros-nodes/message-guidelines/) as the single source of truth.

The rest of this document for validating each item.

## Filename

Each filename must be PascalCase.

If a message exists solely to wrap an array of another message type, append `Array` to the filename.

```bash
DetectedObjectArray.msg  # plural wrapper: contains DetectedObject[] objects
```

## File header comment

If file header is provided, it should briefly state what the message represents and link to external documentation or resources for describing additional context.

## Field comment

Every field must have a comment block immediately above it (no empty line between the comment and the field).

- Describe what the field represents in one line.
- Declare `(required)` or `(optional)`.
  - If `optional`: include `# default: <value>` on a separate comment line.
- Optionally include `# e.g. <value>` to describle an example value.

## Field name

Every field name must be in `snake_case`.

## Field units

### Default units

When a field uses the default unit for its physical dimension, do not add any unit suffix to the field name.

| Dimension     | Default unit | Bad example            | Good example    |
| ------------- | ------------ | ---------------------- | --------------- |
| Distance      | m            | `path_length_m`        | `path_length`   |
| Angular accel | rad/s²       | `angular_accel_radps2` | `angular_accel` |

### Non-default units

When a field intentionally uses a non-default unit, append exactly the suffix from the table below.

| Dimension | Unit      | Approved suffix | Bad alternatives        |
| --------- | --------- | --------------- | ----------------------- |
| Distance  | nanometer | `_nm`           | `_nanometer`            |
| Velocity  | km/h      | `_kmph`         | `_km_h`, `_kmh`, `_kph` |

The unit identifier must appear at the end of the field name.

```bash
float32 kmph_velocity_vehicle # BAD — unit is a prefix
float32 velocity_vehicle_kmph # GOOD — unit is a suffix
```

## Array field

- Use unbounded dynamic arrays (`type[]`), not bounded arrays (`type[N]`).
- Exception: only use `[N]` when the size is a hard physical constraint (e.g. a 4×4 matrix represented as `float64[16]`).

```bash
DetectedObject[]  objects # GOOD
DetectedObject[5] objects # BAD — avoid unless physically fixed size
```

## Constants and enumerations field

- Constant names must be in `CONSTANT_CASE` (all uppercase, words separated by underscores, no leading or trailing underscore).
- A constant group must be **mutually exclusive and collectively exhaustive** for the dimension it represents.
- Each constant must have a preceding `#` comment explaining its meaning.

```txt
# Object classification constants
# Object class is unknown or could not be determined
uint8 OBJECT_UNKNOWN = 0
```
