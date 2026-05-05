# swift-cli-docs-plugin

A Swift Package Manager command plugin that generates beautiful Markdown
documentation for any CLI tool built with [swift-argument-parser][sap].
It reads the tool's `--experimental-dump-help` JSON, applies your YAML
configuration, and renders Markdown via Stencil templates.

[sap]: https://github.com/apple/swift-argument-parser

## Why

The official [`generate-manual`][generate-manual] plugin produces man pages,
and [`generate-docc-reference`][generate-docc-reference] produces DocC. There
was no first-class option for plain Markdown that drops cleanly into a README,
GitHub Pages, mdBook, or MkDocs. This plugin fills that gap.

[generate-manual]: https://github.com/apple/swift-argument-parser/tree/main/Plugins/GenerateManualPlugin
[generate-docc-reference]: https://github.com/swiftlang/swift-argument-parser-docs

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

| Theme | Look |
| --- | --- |
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

## Status

Pre-1.0. The `RenderContext` shape is the public contract for custom themes;
breaking changes will be reflected in the version number.

## License

Apache 2.0.
