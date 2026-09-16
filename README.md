# PTE-100 — Português Técnico Essencial

[English overview](README.en.md) · [Site público](https://forge-z.github.io/pte100/)

[![Status: proposta v0.1](https://img.shields.io/badge/status-proposta%20v0.1-f5a623)](spec/PTE-100-v0.1.md)
[![Licença: Apache-2.0](https://img.shields.io/badge/licen%C3%A7a-Apache--2.0-blue)](LICENSE)
[![Idioma: português](https://img.shields.io/badge/idioma-portugu%C3%AAs-009c3b)](docs/architecture.md)

O PTE-100 é uma proposta aberta de linguagem técnica controlada, criada em português para tornar a documentação mais clara, consistente e fácil de processar por pessoas, fluxos de tradução, linters, sistemas de busca e agentes de IA.

O projeto não é uma tradução, adaptação oficial nem implementação do ASD-STE100. O PTE-100 parte de problemas universais da comunicação técnica, mas define identidade, regras, taxonomia, modelo de conformidade e arquitetura de ferramentas próprios.

> **Estado do projeto:** a versão 0.1 é uma proposta pública experimental, não um padrão estável ou certificado. Português é o idioma normativo; o [README em inglês](README.en.md) é informativo.

## Por que existe

Variação terminológica, frases excessivamente complexas, condições implícitas e estruturas inconsistentes podem dificultar a leitura e acrescentar trabalho à tradução, busca, linting e recuperação por IA. O PTE-100 propõe regras explícitas, vocabulário controlado e estruturas documentais previsíveis para enfrentar esses problemas. Essa é a motivação do projeto, não uma afirmação de eficácia validada por pesquisa ou adoção externa.

## O que já funciona

- [Especificação PTE-100 v0.1](spec/PTE-100-v0.1.md), com escopo, linguagem normativa e conformidade;
- [50 regras experimentais](rules/catalog.md), também disponíveis como [dados YAML](rules/rules.yaml);
- [vocabulário controlado](vocabulary/README.md) e [JSON Schemas](schemas/) públicos;
- [PTE-Lint offline](docs/pte-lint.md), com 21 regras automáticas, entrada Markdown/texto e saída `text`, JSON ou SARIF;
- [revisor local](reviewer-webapp/README.md) para Markdown, texto simples e PDF com camada de texto;
- [exemplos antes/depois](examples/before-after.md) e um [procedimento completo](examples/procedure-pte.md);
- [corpus sintético de regressão](corpus/README.md), com 42 fixtures, e ferramentas de [ingestão explícita de fontes externas](docs/corpus-sources.md);
- [governança](GOVERNANCE.md), [processo de contribuição](CONTRIBUTING.md) e [roteiro público](ROADMAP.md).

As outras 29 regras têm modo `assisted` especificado, mas ainda não são verificadas pelo motor. As fixtures sintéticas não medem precisão linguística. O lint auxilia a revisão: não certifica segurança, correção técnica, conformidade estável ou cumprimento de requisitos legais.

## Exemplo rápido

Antes:

> O operador deverá efetuar a verificação do nível e, caso seja necessário, proceder com o completamento do reservatório, sendo que o motor deve estar desligado.

Depois:

> 1. Desligue o motor.
> 2. Verifique o nível do reservatório.
> 3. Se o nível estiver abaixo da marca **MÍN**, adicione fluido e pare quando o nível alcançar a marca **MÁX**.

O texto revisado usa ações diretas, uma condição explícita, termos consistentes e passos verificáveis.

## Quick Start

Pré-requisitos: Git e **Ruby 3.3.x** (versão de referência: **3.3.12**). O MVP é usado a partir do clone do repositório; ainda não é distribuído como pacote instalável. A CLI usa apenas a biblioteca padrão do Ruby, sem instalação de gems ou Node.js.

```sh
git clone https://github.com/forge-z/pte100.git
cd pte100
ruby bin/pte-lint check examples/procedure-pte.md --format text
```

Resultado esperado:

```text
1 arquivo(s), 0 erro(s), 0 aviso(s)
```

Para obter o mesmo resultado em JSON:

```sh
ruby bin/pte-lint check examples/procedure-pte.md --format json
```

Substitua o caminho pelo seu arquivo Markdown ou texto. Consulte a [documentação do PTE-Lint](docs/pte-lint.md) para configuração, formatos de saída e códigos de retorno. Para revisar no navegador, siga a [instalação do revisor local](reviewer-webapp/README.md), que requer gems adicionais.

### Executar os testes

A suíte completa usa **Bundler 2.6.9** e as dependências do revisor. Na raiz do clone:

```sh
gem install bundler -v 2.6.9
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle install
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle exec rake verify
```

`rake verify` executa testes do motor, CLI, consistência, corpus e revisor, além da validação editorial. O clone e a instalação de dependências precisam de rede; os testes não baixam corpus externo. Veja os comandos de geração e manutenção em [tools/README.md](tools/README.md). O [website](website/README.md) tem build separado com Node.js 22.

### Avaliar a proposta em um piloto

1. Leia os [princípios de projeto](docs/design-principles.md) e a [arquitetura da norma](docs/architecture.md).
2. Selecione um nível de [conformidade](docs/conformance.md).
3. Use [`pte-lint.example.yaml`](pte-lint.example.yaml) como base da configuração do piloto.
4. Registre falsos positivos, exceções e evidências antes/depois, com revisão humana.

## Arquitetura do ecossistema

| Componente | Responsabilidade | Estado |
|---|---|---|
| PTE-100 Core | linguagem, gramática, estrutura e conformidade | proposta v0.1 |
| PTE-200 Vocabulary | registro e distribuição de vocabulários | planejado |
| PTE-300 Domínios | perfis para setores técnicos | planejado |
| PTE-Lint | analisador e formato de diagnósticos | MVP offline (21 regras automáticas) |
| PTE-100 Reviewer | revisão local de Markdown, texto e PDF textual | MVP offline |
| VS Code Extension | feedback durante a escrita | planejado |
| MCP Server | validação e consulta por agentes | planejado |
| API REST | validação remota e registro de termos | planejado |

## Princípios de manutenção

- uma exigência deve ser testável ou marcada como revisão humana;
- mudanças incompatíveis exigem versão principal nova;
- toda regra nova precisa de motivação, contraexemplo, exemplo correto e estratégia de lint;
- decisões normativas são públicas, rastreáveis e orientadas por evidências;
- perfis de domínio estendem o núcleo sem redefinir o significado de suas regras.

## Estrutura do repositório

```text
.
├── .github/              # modelos e automação de contribuição
├── docs/                 # arquitetura e contratos técnicos
├── website/              # landing page pública no GitHub Pages
├── examples/             # exemplos normativos e informativos
├── corpus/               # fixtures, manifesto e snapshots do corpus externo
├── bin/                  # CLI pte-lint (MVP offline)
├── lib/                  # motor Ruby compartilhado (MVP offline)
├── reviewer-webapp/      # revisor local e seus testes
├── rules/                # catálogo humano e fonte YAML das regras
├── schemas/              # JSON Schemas públicos
├── spec/                 # versões publicadas da especificação
├── vocabulary/           # vocabulário controlado e seu schema
├── AGENTS.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── GOVERNANCE.md
├── LICENSE
├── MAINTAINERS.md
├── NOTICE
├── ROADMAP.md
└── SECURITY.md
```

## Participação

Contribuições são bem-vindas em qualquer variedade do português. Use [Issues](https://github.com/forge-z/pte100/issues/new/choose) para bugs, propostas de regra e feedback de pilotos; perguntas gerais podem ir para [Discussions](https://github.com/forge-z/pte100/discussions). Anonimize exemplos e não publique conteúdo confidencial.

Antes de alterar regras ou contratos, siga [CONTRIBUTING.md](CONTRIBUTING.md) e [GOVERNANCE.md](GOVERNANCE.md). Consulte os [mantenedores atuais](MAINTAINERS.md), o [Código de Conduta](CODE_OF_CONDUCT.md) e as [instruções operacionais para agentes](AGENTS.md).

## Licença e atribuição

Código, esquemas, regras, exemplos e documentação são disponibilizados sob a [Apache License 2.0](LICENSE). Consulte também o arquivo [NOTICE](NOTICE).
