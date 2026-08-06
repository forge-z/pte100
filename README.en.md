# PTE-100 — Essential Technical Portuguese

[Versão principal em português](README.md)

PTE-100 is an original, open controlled-language standard for technical documentation in Portuguese. It aims to reduce ambiguity, improve translation and terminology consistency, enable automated linting, and make content safer to retrieve and interpret by humans and AI agents.

PTE-100 is not a translation, official adaptation, or implementation of ASD-STE100. It defines its own identity, rules, conformance model, machine-readable contracts, and open governance.

## Current status

Version 0.1 is a public proposal for pilot use, not a stable or certified standard. The normative language is Portuguese. This English page is informative.

The repository includes:

- the [PTE-100 v0.1 specification](spec/PTE-100-v0.1.md);
- a [human-readable catalog of 50 rules](rules/catalog.md) and its [canonical YAML source](rules/rules.yaml);
- a [controlled vocabulary](vocabulary/README.md);
- [before-and-after examples](examples/before-after.md);
- schemas and plans for PTE-Lint, a CLI, VS Code extension, MCP Server, and REST API;
- public contribution, governance, conduct, security, and release policies.

## Architecture

PTE-100 Core defines the controlled language. Planned companion standards cover vocabulary exchange (PTE-200) and domain profiles (PTE-300). PTE-Lint will be the shared offline-first engine behind the CLI, LSP/VS Code integration, MCP Server, CI output, and REST API.

## Contributing and license

Contributions in any variety of Portuguese are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md). All repository content is licensed under [Apache-2.0](LICENSE).

