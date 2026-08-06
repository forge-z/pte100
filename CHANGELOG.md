# Histórico de mudanças

Este projeto segue *Keep a Changelog* e versiona a norma conforme `GOVERNANCE.md`.

## [Não publicado]

### Planejado

- implementação assistida e pacote instalável do PTE-Lint;
- fixtures de conformidade por regra;
- resultados dos primeiros pilotos.

### Adicionado

- MVP offline do PTE-Lint para as 21 regras automáticas;
- CLI `bin/pte-lint` com saída texto, JSON e SARIF;
- corpus sintético anotado com 42 fixtures e testes Minitest;
- verificações de consistência entre vocabulário, regras, catálogo e exemplos.
- dogfooding bloqueante do procedimento canônico na CI;
- heurísticas do MVP ajustadas para ignorar identificadores, siglas normativas, versões e seções.

## [0.1] — 2026-08-06

### Adicionado

- especificação inicial PTE-100 Core;
- catálogo com 50 regras e representação YAML;
- vocabulário controlado inicial;
- arquitetura de PTE-Lint, CLI, extensão VS Code, MCP Server e API REST;
- governança, contribuição, segurança, exemplos e roteiro.

[Não publicado]: https://github.com/pte-100/pte-100/compare/v0.1...HEAD
[0.1]: https://github.com/pte-100/pte-100/releases/tag/v0.1
