# Histórico de mudanças

Este projeto segue *Keep a Changelog* e versiona a norma conforme [GOVERNANCE.md](GOVERNANCE.md). A proposta PTE-100 `0.1`, o identificador do motor PTE-Lint `0.1.0` e o identificador do serviço local Reviewer `0.2.0` são distintos; os dois últimos não indicam releases ou pacotes publicados separadamente.

## [Não publicado]

Esta seção registra ferramentas e manutenção em desenvolvimento. O snapshot depois marcado como `v0.1` já continha itens desta seção; a publicação retrospectiva da tag não os reclassifica como ferramentas estáveis.

### Planejado

- implementação assistida e pacote instalável do PTE-Lint;
- ampliação das fixtures para a cobertura prevista em [docs/pte-lint.md](docs/pte-lint.md#conjunto-de-conformidade);
- resultados dos primeiros pilotos.

### Adicionado

- landing page pública em `website/`, publicada pelo GitHub Pages;
- MVP offline do PTE-Lint para as 21 regras automáticas;
- CLI `bin/pte-lint` com saída texto, JSON e SARIF;
- corpus sintético de regressão com 42 fixtures (uma positiva e uma negativa por regra automática) e testes Minitest; não é uma medição de precisão linguística;
- manifesto e ferramentas de ingestão explícita de corpus externo, com metadados de um snapshot de 215 unidades de três fontes; o texto fica em cache local e não há anotação humana publicada desse conjunto;
- verificações de consistência entre vocabulário, regras, catálogo e exemplos, incluindo sintaxe dos schemas JSON, sem validar instâncias contra esses schemas;
- [Reviewer local](reviewer-webapp/README.md) para Markdown, texto e PDF com camada de texto, compartilhando o motor Ruby;
- formulários de bug, proposta de regra e feedback de piloto, template de PR, onboarding PT/EN e instruções em `AGENTS.md` e `MAINTAINERS.md` na [Fase 1](https://github.com/forge-z/pte100/pull/4).

### Corrigido

- tratamento de caminhos/configuração ausentes, contagem de arquivos, `--stdin-filename` e `fail_on: never` na CLI;
- offsets UTF-8 e intervalos de múltiplas linhas, análise após títulos e primeira ocorrência de siglas no motor;
- controles de Host/Origin e sessão, concorrência de revisão, invalidação de resultados e limpeza no cliente do Reviewer;
- varredura editorial de dependências e saídas de build, com inclusão das suítes do revisor em `rake verify`.

Essas correções foram integradas em [`10cfb7a`](https://github.com/forge-z/pte100/commit/10cfb7aa580237e1281d8c2d64022d1951ae7162). A [auditoria histórica](docs/audits/2026-09-07-improvement-review.md) preserva as evidências e distingue os critérios ainda pendentes.

### Manutenção

- CI de validação original removida em [`c932682`](https://github.com/forge-z/pte100/commit/c932682) e restaurada como [workflow `Verify`](.github/workflows/verify.yml) na Fase 1, com Ruby 3.3.12, Bundler 2.6.9, `rake verify`, regeneração de catálogo/fixtures e build do site com Node.js 22;
- dogfooding limitado ao procedimento canônico: o workflow restaurado exige um arquivo, zero erros e zero avisos; isso não comprova precisão linguística nem adoção externa;
- heurísticas do MVP para identificadores, siglas normativas, versões e seções, com regressões locais;
- auditoria de setembro arquivada com o corpo histórico preservado e link de compatibilidade em `PLANO-DE-MELHORIA.md`.

## [0.1] — 2026-08-06

**Proposta pública experimental.** A data acima identifica a proposta e o snapshot histórico [`0783eab`](https://github.com/forge-z/pte100/commit/0783eab8ef3fe40fa87cb92c94902dd734cfa353); coincide com `date-released` em `CITATION.cff`. A tag anotada `v0.1` e a [prerelease no GitHub][0.1] foram publicadas retrospectivamente em **16 de setembro de 2026**. Essa publicação não inclui as correções posteriores do motor/revisor nem a CI da Fase 1.

### Adicionado

- especificação inicial PTE-100 Core;
- catálogo com 50 regras e representação YAML;
- vocabulário controlado inicial;
- documentação de arquitetura de PTE-Lint, CLI, extensão VS Code, MCP Server e API REST; as integrações planejadas não são implementações entregues;
- governança, contribuição, segurança, exemplos e roteiro.

[Não publicado]: https://github.com/forge-z/pte100/compare/v0.1...HEAD
[0.1]: https://github.com/forge-z/pte100/releases/tag/v0.1
