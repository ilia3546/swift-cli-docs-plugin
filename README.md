# Swift CLI Docs Plugin

[![CI](https://github.com/ilia3546/swift-cli-docs-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/ilia3546/swift-cli-docs-plugin/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Filia3546%2Fswift-cli-docs-plugin%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ilia3546/swift-cli-docs-plugin)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Filia3546%2Fswift-cli-docs-plugin%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ilia3546/swift-cli-docs-plugin)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Support on Boosty](https://img.shields.io/badge/support-Boosty-f15f2c?logo=boosty&logoColor=white)](https://boosty.to/ilia3546/donate)

**Turn any Swift CLI into beautiful Markdown documentation with a single command.**

`swift-cli-docs-plugin` is an SPM command plugin for tools built with
[swift-argument-parser][sap]. It introspects your CLI, applies a tiny YAML
config, and renders polished Markdown that drops straight into your README,
GitHub Pages, mdBook, or MkDocs — no DocC, no man pages, no hand-written
reference tables.

```bash
swift package --allow-writing-to-package-directory generate-docs
```

That's it. Your `docs/` folder now contains a per-command Markdown reference
with synopses, argument tables, examples, and cross-links.

[sap]: https://github.com/apple/swift-argument-parser

## Why

Apple ships two doc generators for `swift-argument-parser`:

- [`GenerateManual`][generate-manual] produces man pages.
- [`GenerateDoccReference`][generate-docc-reference] produces DocC.

Neither produces plain Markdown — the format that actually renders on GitHub,
in static site generators, and in any editor your contributors already use.
This plugin fills that gap, with three built-in themes and a Stencil-based
template system for when you need something custom.

[generate-manual]: https://github.com/apple/swift-argument-parser/tree/main/Plugins/GenerateManual
[generate-docc-reference]: https://github.com/apple/swift-argument-parser/tree/main/Plugins/GenerateDoccReference

## Features

- **Zero-config defaults.** Point it at an executable target and get a clean,
  readable doc set immediately.
- **Three built-in themes** (`default`, `minimal`, `github`) — drop-in styles
  for different rendering targets.
- **Custom themes via [Stencil][stencil]** — override one partial or
  rebuild from scratch, with a stable, pre-computed view-model.
- **Single-file or multi-file output.** One big `CLI.md`, or one file per
  command with an `INDEX.md`.
- **Full subcommand trees.** Nested commands get their own pages, anchors,
  and back-links automatically.
- **YAML config + CLI flag overrides.** Commit your defaults; tweak per-run
  without editing files.
- **Per-command overrides.** Patch abstracts, append examples, or hide
  internal commands without touching your CLI source.
- **macOS and Linux**, Swift 5.9 and 6.0, fully tested in CI.

[stencil]: https://github.com/stencilproject/Stencil

## Quick start

Add the plugin to your package's dependencies:

```swift
.package(url: "https://github.com/ilia3546/swift-cli-docs-plugin", from: "0.1.0"),
```

Generate docs for your CLI:

```bash
swift package --allow-writing-to-package-directory generate-docs
```

You'll find Markdown output under `docs/` (configurable). For a CLI with
multiple executable targets, pass `--target <name>`.

## Configuration

Drop a `.swift-cli-docs.yml` next to your `Package.swift`. All keys are optional.

```yaml
target: MyCLI

output:
  directory: docs
  layout: multi-file        # multi-file | single-file
  filename: "{command}.md"
  index: INDEX.md

metadata:
  title: MyCLI
  description: A sweet little CLI.
  version: 1.2.3
  repository: https://github.com/me/mycli

theme:
  name: default            # default | minimal | github
  path: themes/my-theme    # optional: path to a directory of .stencil files
  headingDepth: 1
  toc: true
  showAliases: true
  showHidden: false
  codeFence: bash
  variables:
    accent: "🚀"

sections:
  order: [overview, usage, arguments, options, flags, subcommands, examples, footer]
  custom:
    overview: docs/snippets/overview.md
    footer: docs/snippets/footer.md

include: ["*"]
exclude: ["mycli internal-*"]

overrides:
  "mycli build":
    abstract: "Build the project."
    examples:
      - title: "Release build"
        code: "mycli build --release"
```

CLI flags override YAML values:

```bash
swift package generate-docs \
  --target MyCLI \
  --layout single-file \
  --theme github \
  --output docs/cli
```

## Built-in themes

| Theme     | Look |
| ---       | --- |
| `default` | Tables for arguments, simple headings, no emoji. Works anywhere Markdown does. |
| `minimal` | Bullet lists instead of tables, no TOC by default. Compact for small CLIs. |
| `github`  | `<details>` blocks, badges, suited for GitHub README rendering. |

## Custom themes

A theme is a directory of Stencil templates. Two files are required at the
root: `command.stencil` (one command) and `index.stencil` (the entry index for
multi-file mode). For single-file mode, supply `single.stencil` as well.

Point `theme.path` at your directory. Missing files fall back to the `default`
theme automatically, so you can override one partial without re-implementing
the whole thing.

### RenderContext (template variables)

Templates receive a stable, pre-computed view-model. No need for filters that
build synopses, escape Markdown, or compute links — that all happens in Swift.

```text
RenderContext
  meta:    { title, description?, version?, repository? }
  theme:   { name, headingDepth, toc, showAliases, codeFence, emoji, variables }
  command: CommandView?     # in command.stencil
  commands: [CommandView]   # in single.stencil
  index:   IndexView?       # in index.stencil

CommandView
  name, fullPath, anchor, headingPrefix
  abstract, abstractEscaped
  discussion, discussionEscaped
  aliases: [String], hasAliases
  synopsis: String
  argumentSections: [ { title, kind, arguments: [ArgumentView] } ]
  hasArguments
  subcommands: [ { name, fullPath, abstract, abstractEscaped, link } ]
  hasSubcommands
  examples: [ { title, titleEscaped, code, codeFenced } ]
  hasExamples
  customSections: [String: String]
  isHidden

ArgumentView
  kind                    # "positional" | "option" | "flag"
  displayName             # "-v, --verbose <level>"
  primaryName, anchor
  description, descriptionEscaped
  defaultDisplay, hasDefault
  isRequired, isRepeating
  valueRangeText, hasValueRange
```

The only filter the engine registers is `mdEscape`, for defensive escaping of
arbitrary `theme.variables` values. Everything else is precomputed.

## Adding `swift-cli-docs-plugin` as a Dependency

To use the plugin in a SwiftPM project, add it to the dependencies for your
package:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/ilia3546/swift-cli-docs-plugin", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(name: "<command-line-tool>", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
```

The plugin is invoked via `swift package`, so no target-level dependency is
required — adding it at the package level is enough.

## Requirements

- Swift 5.9+
- macOS 12+ or Linux

## Status

Pre-1.0. The `RenderContext` shape is the public contract for custom themes;
breaking changes will be reflected in the version number.

## License

This library is released under the Apache 2.0 license. See [LICENSE](LICENSE) for details.
