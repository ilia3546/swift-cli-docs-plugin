# demo build

_Build the demo project._

**Usage**

```bash
demo build [--release] [--target <target>] <path>
```

## Arguments

| Name | Default | Description |
| --- | --- | --- |
| `<path>` **(required)** | `—` | Path to the project root. |

## Options

| Name | Default | Description |
| --- | --- | --- |
| `-t, --target <target>` | `—` | Build target name. |

## Flags

| Name | Default | Description |
| --- | --- | --- |
| `--release` | `—` | Build in release configuration. |

## Examples

**Build a project in release mode**

```bash
demo build --release /path/to/project
```
