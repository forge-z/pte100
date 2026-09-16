# PTE-100 — Essential Technical Portuguese

[Versão principal em português](README.md) · [Public website](https://forge-z.github.io/pte100/)

[![Verify](https://github.com/forge-z/pte100/actions/workflows/verify.yml/badge.svg)](https://github.com/forge-z/pte100/actions/workflows/verify.yml)

PTE-100 is an open, Portuguese-first controlled technical language proposal designed to make technical documentation clearer, more consistent and easier to process by people, translation workflows, linters, search systems and AI agents.

PTE-100 is not a translation, official adaptation, or implementation of ASD-STE100. It defines its own identity, rules, conformance model, machine-readable contracts, and open governance.

> **Current status:** PTE-100 v0.1 is an experimental public proposal, not a certified or stable standard. Portuguese is the normative language. This English page is informative.

## Why it exists

Terminology variation, overly complex sentences, implicit conditions and inconsistent document structures can make technical content harder to read, translate, lint, search and retrieve with AI. PTE-100 proposes explicit rules, controlled vocabulary and predictable structures to address these problems. This is the project's motivation, not a claim of externally validated effectiveness or adoption.

## What is available

- the [PTE-100 v0.1 specification](spec/PTE-100-v0.1.md);
- a [catalog of 50 experimental rules](rules/catalog.md) and its [canonical YAML source](rules/rules.yaml);
- a [controlled vocabulary](vocabulary/README.md) and public [JSON schemas](schemas/);
- an [offline PTE-Lint MVP](docs/pte-lint.md) that checks 21 automatic rules in Markdown and plain text, with `text`, JSON and SARIF output;
- a [local reviewer](reviewer-webapp/README.md) for Markdown, plain text and PDFs with a text layer;
- [before-and-after examples](examples/before-after.md) and a [complete procedure](examples/procedure-pte.md);
- a [synthetic regression corpus](corpus/README.md) with 42 fixtures and tools for [explicit external corpus ingestion](docs/corpus-sources.md);
- public [governance](GOVERNANCE.md), [contribution guidelines](CONTRIBUTING.md) and a [roadmap](ROADMAP.md).

The remaining 29 rules are specified as `assisted` but are not checked by the engine yet. Synthetic fixtures do not measure linguistic accuracy. Lint supports review; it does not certify safety, technical correctness, stable conformance or legal compliance.

## Quick Start

Prerequisites: Git and **Ruby 3.3.x** (reference version: **3.3.12**). The MVP runs from a repository clone; it is not yet distributed as an installable package. The CLI uses only Ruby's standard library and requires no gems or Node.js installation.

```sh
git clone https://github.com/forge-z/pte100.git
cd pte100
ruby bin/pte-lint check examples/procedure-pte.md --format text
```

Expected output, in Portuguese:

```text
1 arquivo(s), 0 erro(s), 0 aviso(s)
```

For JSON output:

```sh
ruby bin/pte-lint check examples/procedure-pte.md --format json
```

Replace the path with your Markdown or plain text file. See the [PTE-Lint documentation](docs/pte-lint.md) for configuration, output formats and exit codes. For browser-based review, follow the [local reviewer installation guide](reviewer-webapp/README.md); it requires additional gems.

### Run the tests

The complete suite requires **Bundler 2.6.9** and the reviewer dependencies. From the repository root:

```sh
gem install bundler -v 2.6.9
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle install
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle exec rake verify
```

`rake verify` runs engine, CLI, consistency, corpus and reviewer tests, plus editorial validation. Cloning and dependency installation require network access; tests do not download an external corpus. See [tools/README.md](tools/README.md) for generation and maintenance commands. The [website](website/README.md) has a separate build using Node.js 22.

### Evaluate a pilot

Read the [design principles](docs/design-principles.md) and [architecture](docs/architecture.md), choose a [conformance level](docs/conformance.md), and use [`pte-lint.example.yaml`](pte-lint.example.yaml) as a configuration starting point. Record false positives, exceptions and before/after evidence with human review.

## Architecture

PTE-100 Core defines the controlled language. The existing CLI and local reviewer share the Ruby PTE-Lint engine. PTE-200 Vocabulary, PTE-300 domain profiles, a VS Code extension, MCP Server and REST API remain planned work; see the [roadmap](ROADMAP.md). OCR and integrated generative AI are not part of the current MVP.

## Contributing

Contributions in any variety of Portuguese are welcome. Use [Issues](https://github.com/forge-z/pte100/issues/new/choose) for bugs, rule proposals and pilot feedback, or [Discussions](https://github.com/forge-z/pte100/discussions) for general questions. Anonymize examples and do not publish confidential content.

Follow [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md) before changing rules or contracts. See the [current maintainers](MAINTAINERS.md), [Code of Conduct](CODE_OF_CONDUCT.md) and [agent maintenance instructions](AGENTS.md).

## License

Code, schemas, rules, examples and documentation are licensed under [Apache-2.0](LICENSE). See also [NOTICE](NOTICE).
